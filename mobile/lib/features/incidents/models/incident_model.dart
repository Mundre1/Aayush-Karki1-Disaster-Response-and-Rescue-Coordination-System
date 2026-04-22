import 'location_model.dart';
import 'incident_update_model.dart';
import '../../auth/models/user_model.dart';

class IncidentMission {
  final int missionId;
  final int? rescueTeamId;
  final String? rescueTeamName;
  final String? assignedByName;
  final String? missionStatus;
  final DateTime? assignedAt;
  final DateTime? completedAt;

  IncidentMission({
    required this.missionId,
    this.rescueTeamId,
    this.rescueTeamName,
    this.assignedByName,
    this.missionStatus,
    this.assignedAt,
    this.completedAt,
  });
}

class IncidentModel {
  final int incidentId;
  final int userId;
  final int locationId;
  final String title;
  final String description;
  final String severity;
  final String? imageUrl;
  final String status;
  final DateTime reportedAt;
  final DateTime? updatedAt;
  final UserModel? user;
  final LocationModel? location;

  /// Mission IDs when API includes missions (e.g. for volunteer "Request to join").
  final List<int>? missionIds;
  final List<IncidentMission>? missions;

  final List<IncidentUpdateEntry>? incidentUpdates;

  IncidentModel({
    required this.incidentId,
    required this.userId,
    required this.locationId,
    required this.title,
    required this.description,
    required this.severity,
    this.imageUrl,
    required this.status,
    required this.reportedAt,
    this.updatedAt,
    this.user,
    this.location,
    this.missionIds,
    this.missions,
    this.incidentUpdates,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int from either camelCase or snake_case
    int parseInt(String camelKey, String snakeKey) {
      final value = json[camelKey] ?? json[snakeKey];
      if (value == null) {
        throw FormatException('Missing required field: $camelKey or $snakeKey');
      }
      if (value is int) return value;
      if (value is String) return int.parse(value);
      return value as int;
    }

    return IncidentModel(
      incidentId: parseInt('incidentId', 'incident_id'),
      userId: parseInt('userId', 'user_id'),
      locationId: parseInt('locationId', 'location_id'),
      title: json['title'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      imageUrl: json['imageUrl'] ?? json['image_url'] as String?,
      status: json['status'] as String,
      reportedAt: DateTime.parse(json['reportedAt'] ?? json['reported_at']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      user: _asStringKeyedMap(json['user']) != null
          ? UserModel.fromJson(_asStringKeyedMap(json['user'])!)
          : null,
      location: _asStringKeyedMap(json['location']) != null
          ? LocationModel.fromJson(_asStringKeyedMap(json['location'])!)
          : null,
      missionIds: _parseMissionIds(json['missions']),
      missions: _parseMissions(json['missions']),
      incidentUpdates: _parseIncidentUpdates(json['incidentUpdates'] ?? json['incident_updates']),
    );
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static List<IncidentUpdateEntry>? _parseIncidentUpdates(dynamic raw) {
    if (raw == null || raw is! List) return null;
    final list = <IncidentUpdateEntry>[];
    for (final e in raw) {
      final item = _asStringKeyedMap(e);
      if (item != null) {
        try {
          list.add(IncidentUpdateEntry.fromJson(item));
        } catch (_) {}
      }
    }
    return list.isEmpty ? null : list;
  }

  static List<int>? _parseMissionIds(dynamic missions) {
    if (missions == null || missions is! List) return null;
    final ids = <int>[];
    for (final m in missions) {
      final mission = _asStringKeyedMap(m);
      if (mission != null) {
        final id = mission['missionId'] ?? mission['mission_id'];
        if (id != null) {
          final n = id is int ? id : int.tryParse(id.toString());
          if (n != null) ids.add(n);
        }
      }
    }
    return ids.isEmpty ? null : ids;
  }

  static List<IncidentMission>? _parseMissions(dynamic raw) {
    if (raw == null || raw is! List) return null;

    final parsed = <IncidentMission>[];
    for (final item in raw) {
      final missionMap = _asStringKeyedMap(item);
      if (missionMap == null) continue;

      final missionIdRaw = missionMap['missionId'] ?? missionMap['mission_id'];
      final missionId = missionIdRaw is int
          ? missionIdRaw
          : int.tryParse(missionIdRaw?.toString() ?? '');
      if (missionId == null) continue;

      final rescueTeam = _asStringKeyedMap(missionMap['rescueTeam'] ?? missionMap['rescue_team']);
      final assignedBy = _asStringKeyedMap(missionMap['user']);

      final rescueTeamIdRaw = rescueTeam?['teamId'] ??
          rescueTeam?['team_id'] ??
          missionMap['rescueTeamId'] ??
          missionMap['rescue_team_id'];
      final rescueTeamId = rescueTeamIdRaw is int
          ? rescueTeamIdRaw
          : int.tryParse(rescueTeamIdRaw?.toString() ?? '');

      parsed.add(
        IncidentMission(
          missionId: missionId,
          rescueTeamId: rescueTeamId,
          rescueTeamName: rescueTeam?['teamName']?.toString() ??
              rescueTeam?['team_name']?.toString(),
          assignedByName: assignedBy?['name']?.toString(),
          missionStatus: missionMap['missionStatus']?.toString() ??
              missionMap['mission_status']?.toString(),
          assignedAt: _parseDateTime(missionMap['assignedAt'] ?? missionMap['assigned_at']),
          completedAt: _parseDateTime(missionMap['completedAt'] ?? missionMap['completed_at']),
        ),
      );
    }

    return parsed.isEmpty ? null : parsed;
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'severity': severity,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'address': location?.address,
      'district': location?.district,
    };
  }
}
