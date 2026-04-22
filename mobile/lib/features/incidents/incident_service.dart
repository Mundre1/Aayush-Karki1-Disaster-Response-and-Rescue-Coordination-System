import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/config/app_config.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/storage_service.dart';
import 'models/incident_model.dart';

class IncidentService {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivity = ConnectivityService();
  final SyncService _syncService = SyncService();
  final StorageService _storageService = StorageService();

  Map<String, dynamic>? _asStringKeyedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Future<Map<String, dynamic>> reportIncident({
    required String title,
    required String description,
    required String severity,
    required double latitude,
    required double longitude,
    String? address,
    String? district,
    Uint8List? imageBytes,
    String? imageFileName,
    String? imageUrl,
  }) async {
    try {
      final fields = {
        'title': title,
        'description': description,
        'severity': severity,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        if (address != null) 'address': address,
        if (district != null) 'district': district,
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'imageUrl': imageUrl.trim(),
      };

      if (!_connectivity.isOnline) {
        String? filePath;
        if (imageBytes != null && imageFileName != null) {
          // Save image locally for later sync
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/offline_images';
          await Directory(path).create(recursive: true);
          filePath = '$path/${DateTime.now().millisecondsSinceEpoch}_$imageFileName';
          final file = File(filePath);
          await file.writeAsBytes(imageBytes);
        }

        await _syncService.addToQueue(
          type: SyncOperationType.createIncident,
          endpoint: AppConfig.incidentsEndpoint,
          method: 'POST',
          data: fields,
          filePath: filePath,
          fileField: filePath != null ? 'image' : null,
        );

        return {
          'success': true,
          'message': 'Incident saved offline. It will sync when online.',
          'isOffline': true,
        };
      }

      Response response;
      if (imageBytes != null && imageFileName != null) {
        response = await _apiService.postMultipart(
          AppConfig.incidentsEndpoint,
          fields,
          'image',
          imageBytes,
          imageFileName,
        );
      } else {
        response = await _apiService.post(
          AppConfig.incidentsEndpoint,
          body: fields,
        );
      }

      final data = response.data;
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'incident': IncidentModel.fromJson(data['incident']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to report incident',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<List<IncidentModel>> getIncidents({
    String? status,
    String? severity,
    int page = 1,
    int limit = 20,
  }) async {
    if (!_connectivity.isOnline) {
      final cached = _storageService.getCachedIncidents();
      return cached.map((e) => IncidentModel.fromJson(e)).toList();
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (severity != null) queryParams['severity'] = severity;

      final response = await _apiService.get(
        AppConfig.incidentsEndpoint,
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> incidentsJson = data['incidents'] ?? [];

        // Cache the incidents
        await _storageService.cacheIncidents(incidentsJson
            .map(_asStringKeyedMap)
            .whereType<Map<String, dynamic>>()
            .toList());

        final List<IncidentModel> incidents = [];
        for (var i = 0; i < incidentsJson.length; i++) {
          try {
            incidents.add(IncidentModel.fromJson(incidentsJson[i]));
          } catch (e) {
            debugPrint('❌ Error parsing incident at index $i: $e');
          }
        }
        return incidents;
      }
      return [];
    } catch (e) {
      final cached = _storageService.getCachedIncidents();
      return cached.map((e) => IncidentModel.fromJson(e)).toList();
    }
  }

  Future<IncidentModel?> getIncidentById(int id) async {
    try {
      final response = await _apiService.get(
        '${AppConfig.incidentsEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return IncidentModel.fromJson(data['incident']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<IncidentModel>> getMyIncidents() async {
    if (!_connectivity.isOnline) {
      final cached = _storageService.getCachedIncidents();
      // Simple filter: if we had the userId cached we could filter better,
      // but for now we'll just show what's in the box or return empty if we want to be strict.
      // Actually, getMyIncidents usually returns a subset.
      // A better way would be to have a separate box for 'my_incidents'.
      return cached.map((e) => IncidentModel.fromJson(e)).toList();
    }

    try {
      final response = await _apiService.get(
        '${AppConfig.incidentsEndpoint}/my-incidents',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> incidentsJson = data['incidents'] ?? [];

        // We could also cache these in the same box, but we might overwrite the main list.
        // For simplicity, let's just parse and return.

        final List<IncidentModel> incidents = [];
        for (var i = 0; i < incidentsJson.length; i++) {
          try {
            incidents.add(IncidentModel.fromJson(incidentsJson[i]));
          } catch (e) {
            debugPrint('❌ Error parsing my incident at index $i: $e');
          }
        }
        return incidents;
      }
      return [];
    } catch (e) {
      final cached = _storageService.getCachedIncidents();
      return cached.map((e) => IncidentModel.fromJson(e)).toList();
    }
  }

  Future<bool> updateIncidentStatus({
    required int incidentId,
    required String status,
    String? note,
  }) async {
    final body = {'status': status, if (note != null) 'note': note};
    if (!_connectivity.isOnline) {
      await _syncService.addToQueue(
        type: SyncOperationType.updateIncident,
        endpoint: '${AppConfig.incidentsEndpoint}/$incidentId/status',
        method: 'PUT',
        data: body,
      );
      return true;
    }

    try {
      final response = await _apiService.put(
        '${AppConfig.incidentsEndpoint}/$incidentId/status',
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> updateIncident({
    required int incidentId,
    required String title,
    required String description,
    required String severity,
    required double latitude,
    required double longitude,
    String? address,
    String? district,
    Uint8List? imageBytes,
    String? imageFileName,
    String? imageUrl,
  }) async {
    try {
      final fields = {
        'title': title,
        'description': description,
        'severity': severity,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        if (address != null) 'address': address,
        if (district != null) 'district': district,
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'imageUrl': imageUrl.trim(),
      };

      if (!_connectivity.isOnline) {
        String? filePath;
        if (imageBytes != null && imageFileName != null) {
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/offline_images';
          await Directory(path).create(recursive: true);
          filePath = '$path/${DateTime.now().millisecondsSinceEpoch}_$imageFileName';
          final file = File(filePath);
          await file.writeAsBytes(imageBytes);
        }

        await _syncService.addToQueue(
          type: SyncOperationType.updateIncident,
          endpoint: '${AppConfig.incidentsEndpoint}/$incidentId',
          method: 'PUT',
          data: fields,
          filePath: filePath,
          fileField: filePath != null ? 'image' : null,
        );

        return {
          'success': true,
          'message': 'Update saved offline.',
          'isOffline': true,
        };
      }

      Response response;
      if (imageBytes != null && imageFileName != null) {
        response = await _apiService.postMultipart(
          '${AppConfig.incidentsEndpoint}/$incidentId',
          fields,
          'image',
          imageBytes,
          imageFileName,
        );
      } else {
        response = await _apiService.put(
          '${AppConfig.incidentsEndpoint}/$incidentId',
          body: fields,
        );
      }

      final data = response.data;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Incident updated successfully',
          'incident': IncidentModel.fromJson(data['incident']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update incident',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteIncident(int incidentId) async {
    if (!_connectivity.isOnline) {
      await _syncService.addToQueue(
        type: SyncOperationType.deleteIncident,
        endpoint: '${AppConfig.incidentsEndpoint}/$incidentId',
        method: 'DELETE',
        data: {},
      );
      return {'success': true, 'message': 'Delete scheduled offline.', 'isOffline': true};
    }

    try {
      final response = await _apiService.delete(
        '${AppConfig.incidentsEndpoint}/$incidentId',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Incident deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to delete incident',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
