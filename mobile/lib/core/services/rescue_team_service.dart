import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'api_service.dart';
import '../config/app_config.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';
import 'storage_service.dart';
import '../../features/missions/models/mission_model.dart';

class RescueTeamService {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivity = ConnectivityService();
  final SyncService _syncService = SyncService();
  final StorageService _storageService = StorageService();

  /// GET /responders/missions - requires responder/admin role
  Future<List<MissionModel>> getMyMissions() async {
    if (!_connectivity.isOnline) {
      final cached = _storageService.getCachedMissions();
      return cached.map((e) => MissionModel.fromJson(e)).toList();
    }

    try {
      final response = await _apiService.get(
        '${AppConfig.respondersEndpoint}/missions',
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        final list = data?['missions'] as List<dynamic>? ?? [];

        await _storageService.cacheMissions(
          list.map((e) => e as Map<String, dynamic>).toList(),
        );

        return list
            .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('RescueTeamService getMyMissions error: $e');
      final cached = _storageService.getCachedMissions();
      return cached.map((e) => MissionModel.fromJson(e)).toList();
    }
  }

  /// PUT /responders/missions/:id/status - body: { missionStatus }
  Future<Map<String, dynamic>> updateMissionStatus(
    int missionId,
    String missionStatus, {
    String? note,
    Uint8List? imageBytes,
    String? imageFileName,
    String? imageUrl,
    String? imagePath,
  }) async {
    final body = <String, dynamic>{'missionStatus': missionStatus};
    if (note != null && note.trim().isNotEmpty) body['note'] = note.trim();
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      body['imageUrl'] = imageUrl.trim();
    }

    if (!_connectivity.isOnline) {
      await _syncService.addToQueue(
        type: SyncOperationType.missionStatusUpdate,
        endpoint: '${AppConfig.respondersEndpoint}/missions/$missionId/status',
        method: 'PUT',
        data: body,
        filePath: imagePath,
        fileField: imagePath != null ? 'image' : null,
      );
      return {
        'success': true,
        'message': 'Status update saved offline.',
        'isOffline': true,
      };
    }

    try {
      final endpoint =
          '${AppConfig.respondersEndpoint}/missions/$missionId/status';
      Response response;

      if (imagePath != null) {
        response = await _apiService.putMultipartFromFile(
          endpoint,
          body.map((k, v) => MapEntry(k, v.toString())),
          fileField: 'image',
          filePath: imagePath,
        );
      } else if (imageBytes != null && imageFileName != null) {
        response = await _apiService.putMultipart(
          endpoint,
          body.map((k, v) => MapEntry(k, v.toString())),
          fileField: 'image',
          fileBytes: imageBytes,
          fileName: imageFileName,
        );
      } else {
        response = await _apiService.put(endpoint, body: body);
      }

      final data = response.data as Map<String, dynamic>?;
      if (response.statusCode == 200) {
        final mission = data?['mission'];
        return {
          'success': true,
          'message': data?['message'] as String? ?? 'Status updated',
          if (mission != null)
            'mission': MissionModel.fromJson(mission as Map<String, dynamic>),
        };
      }
      return {
        'success': false,
        'message': data?['message'] as String? ?? 'Update failed',
      };
    } catch (e) {
      debugPrint('RescueTeamService updateMissionStatus error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// POST /responders/missions/:id/request
  Future<Map<String, dynamic>> requestMissionAssignment(int missionId) async {
    try {
      final response = await _apiService.post(
        '${AppConfig.respondersEndpoint}/missions/$missionId/request',
        body: {},
      );
      final data = response.data as Map<String, dynamic>?;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              data?['message'] as String? ?? 'Request sent to administrators.',
        };
      }
      return {
        'success': false,
        'message': data?['message'] as String? ?? 'Request failed',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOrganizationMembers() async {
    try {
      final response = await _apiService.get(
        '${AppConfig.respondersEndpoint}/organization/members',
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'organization': data['organization'] as Map<String, dynamic>?,
          'members': data['members'] as List<dynamic>? ?? [],
        };
      }
      return {'success': false, 'message': 'Failed to load members'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// POST /responders/location - body: { latitude, longitude }
  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      await _apiService.post(
        '${AppConfig.respondersEndpoint}/location',
        body: {'latitude': latitude, 'longitude': longitude},
      );
    } catch (e) {
      debugPrint('RescueTeamService updateLocation error: $e');
      // Silently fail or rethrow depending on requirement.
      // Since it's background/periodic, silent fail is usually preferred to avoid spamming UI.
      // But for debugging, we log it.
    }
  }
}
