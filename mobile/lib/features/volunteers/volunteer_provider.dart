import 'package:flutter/foundation.dart';
import '../../core/services/volunteer_service.dart';
import '../../core/services/sync_service.dart';

class VolunteerProvider with ChangeNotifier {
  final VolunteerService _volunteerService = VolunteerService();
  final SyncService _syncService = SyncService();
  VolunteerProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  VolunteerProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _profile != null;
  bool get isApproved => _profile?.isApproved ?? false;

  List<Map<String, dynamic>> _missionRequests = [];
  List<Map<String, dynamic>> get missionRequests => _missionRequests;

  Future<void> loadMissionRequests() async {
    try {
      _missionRequests = await _volunteerService.getMyMissionRequests();
      notifyListeners();
    } catch (_) {
      _missionRequests = [];
      notifyListeners();
    }
  }

  List<SyncItem> get pendingRequests =>
      _syncService.getPendingItems(SyncOperationType.volunteerRequest);

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _volunteerService.getProfile();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> requestToJoinMission(int missionId) async {
    try {
      final result = await _volunteerService.requestToJoinMission(missionId);
      await loadMissionRequests();
      notifyListeners();
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateAvailability(String availability) async {
    try {
      final result = await _volunteerService.updateAvailability(availability);
      if (result['success'] == true) {
        await loadProfile();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Register current user as volunteer. Call after login.
  Future<Map<String, dynamic>> register({
    String? skills,
    String availability = 'available',
  }) async {
    try {
      final result = await _volunteerService.register(
        skills: skills,
        availability: availability,
      );
      if (result['success'] == true) {
        await loadProfile();
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
