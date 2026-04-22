import 'package:flutter/foundation.dart';
import 'incident_service.dart';
import 'models/incident_model.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/sync_service.dart';

class IncidentProvider with ChangeNotifier {
  final IncidentService _incidentService = IncidentService();
  final SocketService _socketService = SocketService();
  final SyncService _syncService = SyncService();
  List<IncidentModel> _incidents = [];

  IncidentProvider() {
    // Listen for sync completions to refresh data
    _syncService.addListener(_onSyncUpdate);
  }

  void _onSyncUpdate() {
    if (!_syncService.hasPendingOperations()) {
      loadIncidents();
      loadMyIncidents();
    } else {
      notifyListeners(); // Update pending counts
    }
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncUpdate);
    super.dispose();
  }
  bool _isLoading = false;
  String? _errorMessage;

  List<IncidentModel> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<SyncItem> get pendingIncidents =>
      _syncService.getPendingItems(SyncOperationType.createIncident);

  void initializeSocketListeners() {
    // Listen for new incidents (mainly for admins)
    _socketService.onNewIncident((data) {
      debugPrint(
        'New incident received via socket: ${data['incident']['title']}',
      );
      // Refresh incidents list to show new incident
      loadIncidents();
    });

    // Listen for mission assignments
    _socketService.onMissionAssigned((data) {
      debugPrint('Mission assigned: ${data.toString()}');
      // Handle mission assignment notification
      // You could show a notification or update the UI
    });

    // Listen for mission status changes
    _socketService.onMissionStatusChanged((data) {
      debugPrint('Mission status changed: ${data.toString()}');
      // Handle mission status updates
    });
  }

  void disposeSocketListeners() {
    _socketService.offNewIncident();
    _socketService.offMissionAssigned();
    _socketService.offMissionStatusChanged();
  }

  Future<void> loadIncidents({String? status, String? severity}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 Loading incidents...');
      final incidents = await _incidentService.getIncidents(
        status: status,
        severity: severity,
      );

      debugPrint('📊 Loaded ${incidents.length} incidents into provider');
      incidents.sort((a, b) {
        int rank(String s) {
          switch (s.toLowerCase()) {
            case 'critical':
              return 0;
            case 'high':
              return 1;
            case 'medium':
              return 2;
            case 'low':
              return 3;
            default:
              return 4;
          }
        }

        // Primary sort: Most recent first
        final dateComparison = b.reportedAt.compareTo(a.reportedAt);
        if (dateComparison != 0) return dateComparison;

        // Secondary sort: Severity priority
        return rank(a.severity).compareTo(rank(b.severity));
      });
      _incidents = incidents;
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Notified listeners with ${_incidents.length} incidents');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading incidents: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = 'Failed to load incidents: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reportIncident({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _incidentService.reportIncident(
        title: title,
        description: description,
        severity: severity,
        latitude: latitude,
        longitude: longitude,
        address: address,
        district: district,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
        imageUrl: imageUrl,
      );

      if (result['success'] == true) {
        // Refresh both public and personal incident lists
        await Future.wait([
          loadIncidents(),
          loadMyIncidents(),
        ]);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to report incident: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<IncidentModel?> getIncidentById(int id) async {
    try {
      return await _incidentService.getIncidentById(id);
    } catch (e) {
      debugPrint('Error loading incident: $e');
      return null;
    }
  }

  List<IncidentModel> _myIncidents = [];
  bool _isLoadingMyIncidents = false;

  List<IncidentModel> get myIncidents => _myIncidents;
  bool get isLoadingMyIncidents => _isLoadingMyIncidents;

  Future<void> loadMyIncidents() async {
    _isLoadingMyIncidents = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 Loading my incidents...');
      _myIncidents = await _incidentService.getMyIncidents();
      _isLoadingMyIncidents = false;
      debugPrint('📊 Loaded ${_myIncidents.length} my incidents into provider');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load my incidents: ${e.toString()}';
      _isLoadingMyIncidents = false;
      notifyListeners();
    }
  }

  Future<bool> updateIncident({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _incidentService.updateIncident(
        incidentId: incidentId,
        title: title,
        description: description,
        severity: severity,
        latitude: latitude,
        longitude: longitude,
        address: address,
        district: district,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
        imageUrl: imageUrl,
      );

      if (result['success'] == true) {
        // Refresh both lists
        await Future.wait([loadIncidents(), loadMyIncidents()]);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update incident: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIncident(int incidentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _incidentService.deleteIncident(incidentId);

      if (result['success'] == true) {
        // Refresh both lists
        await Future.wait([loadIncidents(), loadMyIncidents()]);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete incident: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
