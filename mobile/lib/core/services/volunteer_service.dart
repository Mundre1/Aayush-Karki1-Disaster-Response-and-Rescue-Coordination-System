import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../config/app_config.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';
import 'storage_service.dart';

/// Volunteer profile as returned by GET /volunteers/profile
class VolunteerProfile {
  final int volunteerId;
  final int userId;
  final String? skills;
  final String? availability;
  final bool isApproved;
  final Map<String, dynamic>? user;

  VolunteerProfile({
    required this.volunteerId,
    required this.userId,
    this.skills,
    this.availability,
    required this.isApproved,
    this.user,
  });

  factory VolunteerProfile.fromJson(Map<String, dynamic> json) {
    int parseInt(String c, String s) {
      final v = json[c] ?? json[s];
      if (v == null) throw FormatException('Missing: $c');
      if (v is int) return v;
      if (v is String) return int.parse(v);
      return v as int;
    }

    return VolunteerProfile(
      volunteerId: parseInt('volunteerId', 'volunteer_id'),
      userId: parseInt('userId', 'user_id'),
      skills: json['skills'] as String?,
      availability: json['availability'] as String?,
      isApproved: json['isApproved'] == true || json['is_approved'] == true,
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}

class VolunteerService {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivity = ConnectivityService();
  final SyncService _syncService = SyncService();
  final StorageService _storageService = StorageService();

  /// GET /volunteers/profile - requires auth
  Future<VolunteerProfile?> getProfile() async {
    if (!_connectivity.isOnline) {
      final cached = _storageService.getCachedProfile();
      if (cached != null && cached['volunteer'] != null) {
        return VolunteerProfile.fromJson(cached['volunteer'] as Map<String, dynamic>);
      }
      return null;
    }

    try {
      final response = await _apiService.get(
        '${AppConfig.volunteersEndpoint}/profile',
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        if (data != null && data['volunteer'] != null) {
          await _storageService.cacheProfile(data);
          return VolunteerProfile.fromJson(data['volunteer'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('VolunteerService getProfile error: $e');
      final cached = _storageService.getCachedProfile();
      if (cached != null && cached['volunteer'] != null) {
        return VolunteerProfile.fromJson(cached['volunteer'] as Map<String, dynamic>);
      }
      return null;
    }
  }

  /// GET /volunteers/mission-requests
  Future<List<Map<String, dynamic>>> getMyMissionRequests() async {
    try {
      final response = await _apiService.get(
        '${AppConfig.volunteersEndpoint}/mission-requests',
      );
      if (response.statusCode == 200) {
        final list = response.data['missionRequests'] as List<dynamic>? ?? [];
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('getMyMissionRequests: $e');
      return [];
    }
  }

  /// POST /volunteers/missions/:id/request - request to join a mission
  Future<Map<String, dynamic>> requestToJoinMission(int missionId) async {
    if (!_connectivity.isOnline) {
      await _syncService.addToQueue(
        type: SyncOperationType.volunteerRequest,
        endpoint: '${AppConfig.volunteersEndpoint}/missions/$missionId/request',
        method: 'POST',
        data: {},
      );
      return {'success': true, 'message': 'Request saved offline.', 'isOffline': true};
    }

    try {
      final response = await _apiService.post(
        '${AppConfig.volunteersEndpoint}/missions/$missionId/request',
      );
      final data = response.data as Map<String, dynamic>?;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data?['message'] as String? ?? 'Request submitted',
        };
      }
      return {
        'success': false,
        'message': data?['message'] as String? ?? 'Request failed',
      };
    } catch (e) {
      debugPrint('VolunteerService requestToJoinMission error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// PUT /volunteers/availability
  Future<Map<String, dynamic>> updateAvailability(String availability) async {
    final body = {'availability': availability};
    if (!_connectivity.isOnline) {
      await _syncService.addToQueue(
        type: SyncOperationType.updateAvailability,
        endpoint: '${AppConfig.volunteersEndpoint}/availability',
        method: 'PUT',
        data: body,
      );
      return {'success': true, 'message': 'Availability update saved offline.', 'isOffline': true};
    }

    try {
      final response = await _apiService.put(
        '${AppConfig.volunteersEndpoint}/availability',
        body: body,
      );
      final data = response.data as Map<String, dynamic>?;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data?['message'] as String? ?? 'Availability updated',
        };
      }
      return {
        'success': false,
        'message': data?['message'] as String? ?? 'Update failed',
      };
    } catch (e) {
      debugPrint('VolunteerService updateAvailability error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// POST /volunteers/register - register current user as volunteer (skills, availability)
  Future<Map<String, dynamic>> register({
    String? skills,
    String availability = 'available',
  }) async {
    final body = {
      if (skills != null) 'skills': skills,
      'availability': availability,
    };
    if (!_connectivity.isOnline) {
      await _syncService.addToQueue(
        type: SyncOperationType.volunteerRequest,
        endpoint: '${AppConfig.volunteersEndpoint}/register',
        method: 'POST',
        data: body,
      );
      return {'success': true, 'message': 'Registration saved offline.', 'isOffline': true};
    }

    try {
      final response = await _apiService.post(
        '${AppConfig.volunteersEndpoint}/register',
        body: body,
      );
      final data = response.data as Map<String, dynamic>?;
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data?['message'] as String? ?? 'Registration successful',
        };
      }
      return {
        'success': false,
        'message': data?['message'] as String? ?? 'Registration failed',
      };
    } catch (e) {
      debugPrint('VolunteerService register error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
