import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../../core/config/app_config.dart';
import '../incidents/models/incident_model.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  Map<String, dynamic> _asStringKeyedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asListOfStringKeyedMaps(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw.map(_asStringKeyedMap).toList();
  }

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiService.get(
        '${AppConfig.adminEndpoint}/dashboard/stats',
      );

      if (response.statusCode == 200) {
        final data = _asStringKeyedMap(response.data);
        // Backend (admin.controller.js) returns { stats: {...}, recentIncidents: [...] }
        final stats = _asStringKeyedMap(data['stats']);
        final incidentsJson = data['recentIncidents'] as List<dynamic>? ?? [];
        final recentIncidents = incidentsJson
            .map((e) => IncidentModel.fromJson(_asStringKeyedMap(e)))
            .toList();
        return {
          'success': true,
          'stats': stats,
          'recentIncidents': recentIncidents,
        };
      }
      return {'success': false, 'message': 'Failed to load dashboard stats'};
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get all incidents with filters (admin endpoint)
  Future<List<IncidentModel>> getAllIncidents({
    String? status,
    String? severity,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (severity != null) queryParams['severity'] = severity;

      final response = await _apiService.get(
        '${AppConfig.adminEndpoint}/incidents',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = _asStringKeyedMap(response.data);
        // Backend (admin.controller.js) returns { incidents: [...], pagination: {...} }
        final List<dynamic> incidentsJson = data['incidents'] ?? [];

        final List<IncidentModel> incidents = [];
        for (var json in incidentsJson) {
          try {
            incidents.add(IncidentModel.fromJson(_asStringKeyedMap(json)));
          } catch (e) {
            debugPrint('Error parsing incident: $e');
          }
        }

        return incidents;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting all incidents: $e');
      return [];
    }
  }

  /// Assign rescue team to incident
  Future<Map<String, dynamic>> assignRescueTeam({
    required int incidentId,
    required int rescueTeamId,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConfig.adminEndpoint}/incidents/$incidentId/assign',
        body: {'rescueTeamId': rescueTeamId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Rescue team assigned successfully',
          'mission': response.data['mission'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to assign rescue team',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Delete incident
  Future<Map<String, dynamic>> deleteIncident(int incidentId) async {
    try {
      final response = await _apiService.delete(
        '${AppConfig.adminEndpoint}/incidents/$incidentId',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Incident deleted successfully',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to delete incident',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get volunteers list
  Future<List<Map<String, dynamic>>> getVolunteers({
    bool? isApproved,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (isApproved != null) queryParams['isApproved'] = isApproved.toString();

      final response = await _apiService.get(
        '${AppConfig.adminEndpoint}/volunteers',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = _asStringKeyedMap(response.data);
        // Backend returns { volunteers: [...], pagination: {...} }
        final list = data['volunteers'] as List<dynamic>? ?? [];
        return _asListOfStringKeyedMaps(list);
      }
      return [];
    } catch (e) {
      debugPrint('Error getting volunteers: $e');
      return [];
    }
  }

  /// Approve volunteer
  Future<Map<String, dynamic>> approveVolunteer(int volunteerId) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.adminEndpoint}/volunteers/$volunteerId/approve',
        body: {},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Volunteer approved successfully',
          'volunteer': response.data['volunteer'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to approve volunteer',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get rescue teams list
  Future<List<Map<String, dynamic>>> getRescueTeams({
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (isActive != null) queryParams['isActive'] = isActive.toString();

      final response = await _apiService.get(
        '${AppConfig.adminEndpoint}/rescue-teams',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = _asStringKeyedMap(response.data);
        // Backend returns { rescueTeams: [...], pagination: {...} }
        final list = data['rescueTeams'] as List<dynamic>? ?? [];
        return _asListOfStringKeyedMaps(list);
      }
      return [];
    } catch (e) {
      debugPrint('Error getting rescue teams: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> verifyIncident(int incidentId, {String? note}) async {
    try {
      final response = await _apiService.post(
        AppConfig.adminVerifyIncident(incidentId),
        body: {if (note != null) 'note': note},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message'], 'incident': response.data['incident']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Verify failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getPendingBankDonations() async {
    try {
      final response = await _apiService.get(AppConfig.adminDonationsBankPending);
      if (response.statusCode == 200) {
        final data = _asStringKeyedMap(response.data);
        final list = data['donations'] as List<dynamic>? ?? [];
        return _asListOfStringKeyedMaps(list);
      }
      return [];
    } catch (e) {
      debugPrint('getPendingBankDonations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllDonations({String? status}) async {
    try {
      final response = await _apiService.get(
        AppConfig.donationsEndpoint,
        queryParams: {
          if (status != null && status.isNotEmpty) 'status': status,
          'limit': '200',
        },
      );
      if (response.statusCode == 200) {
        final data = _asStringKeyedMap(response.data);
        final list = data['donations'] as List<dynamic>? ?? [];
        return _asListOfStringKeyedMaps(list);
      }
      return [];
    } catch (e) {
      debugPrint('getAllDonations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> confirmBankDonation(int donationId) async {
    try {
      final response = await _apiService.put(
        AppConfig.adminDonationBankConfirm(donationId),
        body: {},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectBankDonation(int donationId) async {
    try {
      final response = await _apiService.put(
        AppConfig.adminDonationBankReject(donationId),
        body: {},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getVolunteerMissionRequests({String status = 'pending'}) async {
    try {
      final response = await _apiService.get(
        AppConfig.adminVolunteerMissionRequests,
        queryParams: {'status': status},
      );
      if (response.statusCode == 200) {
        final data = _asStringKeyedMap(response.data);
        final list = data['missionRequests'] as List<dynamic>? ?? [];
        return _asListOfStringKeyedMaps(list);
      }
      return [];
    } catch (e) {
      debugPrint('getVolunteerMissionRequests: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> approveMissionRequest(int requestId) async {
    try {
      final response = await _apiService.put(
        AppConfig.adminVolunteerMissionRequestApprove(requestId),
        body: {},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectMissionRequest(int requestId) async {
    try {
      final response = await _apiService.put(
        AppConfig.adminVolunteerMissionRequestReject(requestId),
        body: {},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPendingResponderApprovals() async {
    try {
      final response = await _apiService.get(
        '${AppConfig.adminEndpoint}/responder-approvals/pending',
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'pendingResponders':
              response.data['pendingResponders'] as List<dynamic>? ?? [],
          'pendingOrganizations':
              response.data['pendingOrganizations'] as List<dynamic>? ?? [],
        };
      }
      return {'success': false, 'message': 'Failed to load pending approvals'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> reviewResponder({
    required int responderUserId,
    required bool approve,
  }) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.adminEndpoint}/responders/$responderUserId/review',
        body: {'action': approve ? 'approve' : 'reject'},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> reviewOrganization({
    required int organizationId,
    required bool approve,
  }) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.adminEndpoint}/organizations/$organizationId/review',
        body: {'action': approve ? 'approve' : 'reject'},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOrganizationDetails(int organizationId) async {
    try {
      final response = await _apiService.get(
        '${AppConfig.adminEndpoint}/organizations/$organizationId/details',
      );
      if (response.statusCode == 200) {
        final data = _asStringKeyedMap(response.data);
        return {
          'success': true,
          'organization': _asStringKeyedMap(data['organization']),
        };
      }
      return {'success': false, 'message': 'Failed to load organization details'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
