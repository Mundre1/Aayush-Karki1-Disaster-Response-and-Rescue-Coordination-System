import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import 'connectivity_service.dart';
import 'api_service.dart';

enum SyncOperationType {
  createIncident,
  updateIncident,
  deleteIncident,
  missionStatusUpdate,
  volunteerRequest,
  updateAvailability,
}

class SyncItem {
  final String id;
  final SyncOperationType type;
  final String endpoint;
  final String method;
  final Map<String, dynamic> data;
  final String? filePath; // For image uploads
  final String? fileField;
  final DateTime createdAt;

  SyncItem({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.method,
    required this.data,
    this.filePath,
    this.fileField,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'endpoint': endpoint,
      'method': method,
      'data': data,
      'filePath': filePath,
      'fileField': fileField,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncItem.fromMap(Map<String, dynamic> map) {
    return SyncItem(
      id: map['id'],
      type: SyncOperationType.values.byName(map['type']),
      endpoint: map['endpoint'],
      method: map['method'],
      data: Map<String, dynamic>.from(map['data']),
      filePath: map['filePath'],
      fileField: map['fileField'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class SyncService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final Box _syncBox = Hive.box(AppConfig.syncQueueBox);
  final Uuid _uuid = const Uuid();
  bool _isProcessing = false;

  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal() {
    // Start listening for connectivity changes to trigger sync
    _connectivityService.addListener(_onConnectivityChanged);
    // Trigger initial check
    Future.delayed(const Duration(seconds: 2), () {
      if (_connectivityService.isOnline) {
        processQueue();
      }
    });
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline && !_isProcessing) {
      processQueue();
    }
  }

  Future<void> addToQueue({
    required SyncOperationType type,
    required String endpoint,
    required String method,
    required Map<String, dynamic> data,
    String? filePath,
    String? fileField,
  }) async {
    final item = SyncItem(
      id: _uuid.v4(),
      type: type,
      endpoint: endpoint,
      method: method,
      data: data,
      filePath: filePath,
      fileField: fileField,
      createdAt: DateTime.now(),
    );

    await _syncBox.put(item.id, item.toMap());
    debugPrint('📝 Added to Sync Queue: ${type.name} (ID: ${item.id})');
    notifyListeners();

    if (_connectivityService.isOnline) {
      processQueue();
    }
  }

  Future<void> processQueue() async {
    if (_syncBox.isEmpty || _isProcessing) return;

    _isProcessing = true;
    debugPrint('🔄 Processing Sync Queue (${_syncBox.length} items)...');

    final keys = _syncBox.keys.toList();
    // Sort by creation time to maintain order
    final items = keys.map((key) => SyncItem.fromMap(Map<String, dynamic>.from(_syncBox.get(key)))).toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (var item in items) {
      if (!_connectivityService.isOnline) break;

      int? statusCode;
      try {
        statusCode = await _performSyncAction(item);
      } catch (e) {
        debugPrint('❌ Sync failed for item ${item.id}: $e');
      }

      // Success codes: 200, 201
      if (statusCode == 200 || statusCode == 201) {
        await _syncBox.delete(item.id);
        debugPrint('✅ Sync complete for item ${item.id}');
        notifyListeners();
      } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        // Permanent failure (Client error) - Remove from queue to avoid blocking
        debugPrint('❌ Permanent sync failure ($statusCode) for item ${item.id}. Removing from queue.');
        await _syncBox.delete(item.id);
        notifyListeners();
      } else {
        debugPrint('⚠️ Sync skipped or failed (Status: $statusCode) for item ${item.id}');
      }
    }

    _isProcessing = false;
    debugPrint('🏁 Sync Queue processing finished.');
  }

  /// Returns the status code or null on exception
  Future<int?> _performSyncAction(SyncItem item) async {
    try {
      Response response;
      if (item.filePath != null && item.fileField != null) {
        final file = File(item.filePath!);
        if (!await file.exists()) {
          debugPrint('❌ File does not exist: ${item.filePath}');
          return 200; // Pretend success so it gets deleted from queue
        }

        response = await _apiService.postMultipartFromFile(
          item.endpoint,
          item.data.map((k, v) => MapEntry(k, v.toString())),
          item.fileField!,
          item.filePath!,
        );
      } else {
        if (item.method == 'POST') {
          response = await _apiService.post(item.endpoint, body: item.data);
        } else if (item.method == 'PUT') {
          response = await _apiService.put(item.endpoint, body: item.data);
        } else if (item.method == 'DELETE') {
          response = await _apiService.delete(item.endpoint);
        } else {
          return 405; // Method not allowed
        }
      }
      return response.statusCode;
    } on DioException catch (e) {
      return e.response?.statusCode;
    } catch (e) {
      debugPrint('Sync action error for ${item.type.name}: $e');
      return null;
    }
  }

  List<SyncItem> getPendingItems(SyncOperationType type) {
    return _syncBox.values
        .map((e) => SyncItem.fromMap(Map<String, dynamic>.from(e)))
        .where((item) => item.type == type)
        .toList();
  }

  bool hasPendingOperations() {
    return _syncBox.isNotEmpty;
  }

  Future<void> syncNow() async {
    if (_connectivityService.isOnline) {
      await processQueue();
    }
  }
}
