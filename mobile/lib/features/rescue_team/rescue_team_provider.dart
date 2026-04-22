import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../../core/services/rescue_team_service.dart';
import '../../features/missions/models/mission_model.dart';
import '../../core/services/socket_service.dart';

class RescueTeamProvider with ChangeNotifier {
  final RescueTeamService _rescueTeamService = RescueTeamService();
  List<MissionModel> _missions = [];
  List<Map<String, dynamic>> _organizationMembers = [];
  Map<String, dynamic>? _organizationInfo;
  bool _isLoading = false;
  String? _errorMessage;

  List<MissionModel> get missions => _missions;
  List<Map<String, dynamic>> get organizationMembers => _organizationMembers;
  Map<String, dynamic>? get organizationInfo => _organizationInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RescueTeamProvider() {
    _initSocketListener();
  }

  void _initSocketListener() {
    SocketService().onMissionAssigned((data) {
      debugPrint('🔔 New mission assigned via socket: $data');
      try {
        final mission = MissionModel.fromJson(data);
        // Only add if not already in list
        if (!_missions.any((m) => m.missionId == mission.missionId)) {
          _missions.insert(0, mission);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error parsing mission assigned data: $e');
      }
    });
  }

  Future<void> loadMissions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _missions = await _rescueTeamService.getMyMissions();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _missions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateMissionStatus(
    int missionId,
    String missionStatus, {
    String? note,
    Uint8List? imageBytes,
    String? imageFileName,
    String? imageUrl,
    String? imagePath,
  }) async {
    try {
      final result = await _rescueTeamService.updateMissionStatus(
        missionId,
        missionStatus,
        note: note,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
        imageUrl: imageUrl,
        imagePath: imagePath,
      );
      if (result['success'] == true) {
        await loadMissions();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    await _rescueTeamService.updateLocation(latitude, longitude);
  }

  Future<Map<String, dynamic>> requestMissionAssignment(int missionId) async {
    try {
      return await _rescueTeamService.requestMissionAssignment(missionId);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loadOrganizationMembers() async {
    try {
      final result = await _rescueTeamService.getOrganizationMembers();
      if (result['success'] == true) {
        _organizationInfo = result['organization'] as Map<String, dynamic>?;
        _organizationMembers = (result['members'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
