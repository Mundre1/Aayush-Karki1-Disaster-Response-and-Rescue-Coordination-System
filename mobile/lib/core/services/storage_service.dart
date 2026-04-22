import 'package:hive/hive.dart';
import '../config/app_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Box for incidents
  final Box _incidentsBox = Hive.box(AppConfig.incidentsBox);

  // Box for user profile
  final Box _profileBox = Hive.box(AppConfig.userProfileBox);

  // Box for missions
  final Box _missionsBox = Hive.box(AppConfig.missionsBox);

  // Box for notifications
  final Box _notificationsBox = Hive.box(AppConfig.notificationsBox);

  // Incidents Caching
  Future<void> cacheIncidents(List<Map<String, dynamic>> incidents) async {
    await _incidentsBox.clear();
    for (var incident in incidents) {
      final id = incident['incidentId'] ?? incident['incident_id'];
      await _incidentsBox.put(id.toString(), incident);
    }
  }

  List<Map<String, dynamic>> getCachedIncidents() {
    return _incidentsBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Profile Caching
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    await _profileBox.put('current_user', profile);
  }

  Map<String, dynamic>? getCachedProfile() {
    final data = _profileBox.get('current_user');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  // Missions Caching
  Future<void> cacheMissions(List<Map<String, dynamic>> missions) async {
    await _missionsBox.clear();
    for (var mission in missions) {
      final id = mission['missionId'] ?? mission['mission_id'];
      await _missionsBox.put(id.toString(), mission);
    }
  }

  List<Map<String, dynamic>> getCachedMissions() {
    return _missionsBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Notifications Caching
  Future<void> cacheNotifications(List<Map<String, dynamic>> notifications) async {
    await _notificationsBox.clear();
    for (var notification in notifications) {
      final id = notification['notificationId'] ?? notification['notification_id'];
      await _notificationsBox.put(id.toString(), notification);
    }
  }

  List<Map<String, dynamic>> getCachedNotifications() {
    return _notificationsBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> clearAll() async {
    await _incidentsBox.clear();
    await _profileBox.clear();
    await _missionsBox.clear();
    await _notificationsBox.clear();
  }
}
