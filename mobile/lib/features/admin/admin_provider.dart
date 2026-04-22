import 'package:flutter/foundation.dart';
import 'admin_service.dart';
import '../incidents/models/incident_model.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();

  // Dashboard stats
  Map<String, dynamic>? _dashboardStats;
  List<IncidentModel> _recentIncidents = [];
  bool _isLoadingStats = false;
  String? _statsError;
  DateTime? _lastStatsUpdated;

  // Incidents
  List<IncidentModel> _allIncidents = [];
  bool _isLoadingIncidents = false;
  String? _incidentsError;

  // Volunteers
  List<Map<String, dynamic>> _volunteers = [];
  bool _isLoadingVolunteers = false;
  String? _volunteersError;

  // Rescue Teams
  List<Map<String, dynamic>> _rescueTeams = [];
  bool _isLoadingRescueTeams = false;
  String? _rescueTeamsError;

  // Getters
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<IncidentModel> get recentIncidents => _recentIncidents;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;
  DateTime? get lastStatsUpdated => _lastStatsUpdated;

  List<IncidentModel> get allIncidents => _allIncidents;
  bool get isLoadingIncidents => _isLoadingIncidents;
  String? get incidentsError => _incidentsError;

  List<Map<String, dynamic>> get volunteers => _volunteers;
  bool get isLoadingVolunteers => _isLoadingVolunteers;
  String? get volunteersError => _volunteersError;

  List<Map<String, dynamic>> get rescueTeams => _rescueTeams;
  bool get isLoadingRescueTeams => _isLoadingRescueTeams;
  String? get rescueTeamsError => _rescueTeamsError;

  /// Load dashboard statistics
  Future<void> loadDashboardStats() async {
    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      final result = await _adminService.getDashboardStats();
      if (result['success'] == true) {
        _dashboardStats = result['stats'] as Map<String, dynamic>?;
        _recentIncidents =
            result['recentIncidents'] as List<IncidentModel>? ?? [];
        _lastStatsUpdated = DateTime.now();
      } else {
        _statsError = result['message'] as String? ?? 'Failed to load stats';
      }
    } catch (e) {
      _statsError = 'Error loading dashboard stats: ${e.toString()}';
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Load all incidents with filters
  Future<void> loadAllIncidents({
    String? status,
    String? severity,
    int page = 1,
  }) async {
    _isLoadingIncidents = true;
    _incidentsError = null;
    notifyListeners();

    try {
      final incidents = await _adminService.getAllIncidents(
        status: status,
        severity: severity,
        page: page,
      );
      _allIncidents = incidents;
    } catch (e) {
      _incidentsError = 'Error loading incidents: ${e.toString()}';
    } finally {
      _isLoadingIncidents = false;
      notifyListeners();
    }
  }

  /// Assign rescue team to incident
  Future<Map<String, dynamic>> assignRescueTeam({
    required int incidentId,
    required int rescueTeamId,
  }) async {
    try {
      final result = await _adminService.assignRescueTeam(
        incidentId: incidentId,
        rescueTeamId: rescueTeamId,
      );

      if (result['success'] == true) {
        // Refresh incidents list
        await loadAllIncidents();
        await loadDashboardStats();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Delete incident
  Future<Map<String, dynamic>> deleteIncident(int incidentId) async {
    try {
      final result = await _adminService.deleteIncident(incidentId);

      if (result['success'] == true) {
        // Refresh incidents list
        _allIncidents.removeWhere((i) => i.incidentId == incidentId);
        await loadDashboardStats();
        notifyListeners();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Load volunteers
  Future<void> loadVolunteers({bool? isApproved}) async {
    _isLoadingVolunteers = true;
    _volunteersError = null;
    notifyListeners();

    try {
      final volunteers = await _adminService.getVolunteers(
        isApproved: isApproved,
      );
      _volunteers = volunteers;
    } catch (e) {
      _volunteersError = 'Error loading volunteers: ${e.toString()}';
    } finally {
      _isLoadingVolunteers = false;
      notifyListeners();
    }
  }

  /// Approve volunteer
  Future<Map<String, dynamic>> approveVolunteer(int volunteerId) async {
    try {
      final result = await _adminService.approveVolunteer(volunteerId);

      if (result['success'] == true) {
        // Update volunteer in list
        final index = _volunteers.indexWhere(
          (v) => v['volunteerId'] == volunteerId,
        );
        if (index != -1 && result['volunteer'] != null) {
          _volunteers[index] = result['volunteer'] as Map<String, dynamic>;
        }
        notifyListeners();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Load rescue teams
  Future<void> loadRescueTeams({bool? isActive}) async {
    _isLoadingRescueTeams = true;
    _rescueTeamsError = null;
    notifyListeners();

    try {
      final teams = await _adminService.getRescueTeams(isActive: isActive);
      _rescueTeams = teams;
    } catch (e) {
      _rescueTeamsError = 'Error loading rescue teams: ${e.toString()}';
    } finally {
      _isLoadingRescueTeams = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _pendingBankDonations = [];
  List<Map<String, dynamic>> _allDonations = [];
  List<Map<String, dynamic>> _volunteerMissionRequests = [];
  List<Map<String, dynamic>> _pendingResponders = [];
  List<Map<String, dynamic>> _pendingOrganizations = [];
  bool _loadingBankDonations = false;
  bool _loadingAllDonations = false;
  bool _loadingMissionRequests = false;
  bool _loadingResponderApprovals = false;

  List<Map<String, dynamic>> get pendingBankDonations => _pendingBankDonations;
  List<Map<String, dynamic>> get allDonations => _allDonations;
  List<Map<String, dynamic>> get volunteerMissionRequests => _volunteerMissionRequests;
  List<Map<String, dynamic>> get pendingResponders => _pendingResponders;
  List<Map<String, dynamic>> get pendingOrganizations => _pendingOrganizations;
  bool get loadingBankDonations => _loadingBankDonations;
  bool get loadingAllDonations => _loadingAllDonations;
  bool get loadingMissionRequests => _loadingMissionRequests;
  bool get loadingResponderApprovals => _loadingResponderApprovals;

  Future<void> loadPendingBankDonations() async {
    _loadingBankDonations = true;
    notifyListeners();
    try {
      _pendingBankDonations = await _adminService.getPendingBankDonations();
    } finally {
      _loadingBankDonations = false;
      notifyListeners();
    }
  }

  Future<void> loadAllDonations({String? status}) async {
    _loadingAllDonations = true;
    notifyListeners();
    try {
      _allDonations = await _adminService.getAllDonations(status: status);
    } finally {
      _loadingAllDonations = false;
      notifyListeners();
    }
  }

  Future<void> loadVolunteerMissionRequests({String status = 'pending'}) async {
    _loadingMissionRequests = true;
    notifyListeners();
    try {
      _volunteerMissionRequests =
          await _adminService.getVolunteerMissionRequests(status: status);
    } finally {
      _loadingMissionRequests = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> verifyIncident(int incidentId, {String? note}) async {
    final r = await _adminService.verifyIncident(incidentId, note: note);
    if (r['success'] == true) {
      await loadAllIncidents();
      await loadDashboardStats();
    }
    return r;
  }

  Future<Map<String, dynamic>> confirmBankDonation(int donationId) async {
    final r = await _adminService.confirmBankDonation(donationId);
    if (r['success'] == true) {
      await loadPendingBankDonations();
      await loadAllDonations();
    }
    return r;
  }

  Future<Map<String, dynamic>> rejectBankDonation(int donationId) async {
    final r = await _adminService.rejectBankDonation(donationId);
    if (r['success'] == true) {
      await loadPendingBankDonations();
      await loadAllDonations();
    }
    return r;
  }

  Future<Map<String, dynamic>> approveMissionRequest(int requestId) async {
    final r = await _adminService.approveMissionRequest(requestId);
    if (r['success'] == true) await loadVolunteerMissionRequests();
    return r;
  }

  Future<Map<String, dynamic>> rejectMissionRequest(int requestId) async {
    final r = await _adminService.rejectMissionRequest(requestId);
    if (r['success'] == true) await loadVolunteerMissionRequests();
    return r;
  }

  Future<void> loadPendingResponderApprovals() async {
    _loadingResponderApprovals = true;
    notifyListeners();
    try {
      final result = await _adminService.getPendingResponderApprovals();
      if (result['success'] == true) {
        _pendingResponders = (result['pendingResponders'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _pendingOrganizations = (result['pendingOrganizations'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    } finally {
      _loadingResponderApprovals = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> reviewResponder({
    required int responderUserId,
    required bool approve,
  }) async {
    final r = await _adminService.reviewResponder(
      responderUserId: responderUserId,
      approve: approve,
    );
    if (r['success'] == true) await loadPendingResponderApprovals();
    return r;
  }

  Future<Map<String, dynamic>> reviewOrganization({
    required int organizationId,
    required bool approve,
  }) async {
    final r = await _adminService.reviewOrganization(
      organizationId: organizationId,
      approve: approve,
    );
    if (r['success'] == true) await loadPendingResponderApprovals();
    return r;
  }

  Future<Map<String, dynamic>> getOrganizationDetails(int organizationId) async {
    return _adminService.getOrganizationDetails(organizationId);
  }
}
