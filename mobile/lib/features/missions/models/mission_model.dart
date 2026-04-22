import '../../incidents/models/location_model.dart';

/// Minimal incident info embedded in mission response (backend include).
class MissionIncidentInfo {
  final int incidentId;
  final String title;
  final String description;
  final String severity;
  final String status;
  final LocationModel? location;
  final String? reporterName;
  final String? reporterPhone;

  MissionIncidentInfo({
    required this.incidentId,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    this.location,
    this.reporterName,
    this.reporterPhone,
  });

  factory MissionIncidentInfo.fromJson(Map<String, dynamic> json) {
    int parseInt(String c, String s) {
      final v = json[c] ?? json[s];
      if (v == null) throw FormatException('Missing: $c');
      if (v is int) return v;
      if (v is String) return int.parse(v);
      return v as int;
    }

    final user = json['user'] as Map<String, dynamic>?;
    return MissionIncidentInfo(
      incidentId: parseInt('incidentId', 'incident_id'),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      reporterName: user?['name'] as String?,
      reporterPhone: user?['phone'] as String?,
    );
  }
}

/// Rescue team info in mission response.
class RescueTeamInfo {
  final int teamId;
  final String teamName;
  final String? specialization;

  RescueTeamInfo({
    required this.teamId,
    required this.teamName,
    this.specialization,
  });

  factory RescueTeamInfo.fromJson(Map<String, dynamic> json) {
    int parseInt(List<String> keys) {
      dynamic v;
      for (final key in keys) {
        v = json[key];
        if (v != null) break;
      }
      if (v == null) throw const FormatException('Missing: teamId');
      if (v is int) return v;
      if (v is String) return int.parse(v);
      return v as int;
    }

    return RescueTeamInfo(
      teamId: parseInt(['teamId', 'team_id', 'organizationId', 'organization_id']),
      teamName: json['teamName'] as String? ??
          json['team_name'] as String? ??
          json['organizationName'] as String? ??
          json['organization_name'] as String? ??
          '',
      specialization: json['specialization'] as String?,
    );
  }
}

class MissionModel {
  final int missionId;
  final int incidentId;
  final int? rescueTeamId;
  final int? userId;
  final String missionStatus;
  final DateTime assignedAt;
  final DateTime? completedAt;
  final MissionIncidentInfo? incident;
  final RescueTeamInfo? rescueTeam;

  MissionModel({
    required this.missionId,
    required this.incidentId,
    this.rescueTeamId,
    this.userId,
    required this.missionStatus,
    required this.assignedAt,
    this.completedAt,
    this.incident,
    this.rescueTeam,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    int parseInt(String c, String s) {
      final v = json[c] ?? json[s];
      if (v == null) throw FormatException('Missing: $c');
      if (v is int) return v;
      if (v is String) return int.parse(v);
      return v as int;
    }

    int? parseIntOpt(String c, String s, Map<String, dynamic> m) {
      final v = m[c] ?? m[s];
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    DateTime? parseDate(String c, String s) {
      final v = json[c] ?? json[s];
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    final organizationId = parseIntOpt('organizationId', 'organization_id', json);
    final rescueTeamId = parseIntOpt('rescueTeamId', 'rescue_team_id', json);

    return MissionModel(
      missionId: parseInt('missionId', 'mission_id'),
      incidentId: parseInt('incidentId', 'incident_id'),
      rescueTeamId: organizationId ?? rescueTeamId,
      userId: parseIntOpt('userId', 'user_id', json),
      missionStatus:
          json['missionStatus'] as String? ??
          json['mission_status'] as String? ??
          'assigned',
      assignedAt: parseDate('assignedAt', 'assigned_at') ?? DateTime.now(),
      completedAt: parseDate('completedAt', 'completed_at'),
      incident: json['incident'] != null
          ? MissionIncidentInfo.fromJson(
              json['incident'] as Map<String, dynamic>,
            )
          : null,
      rescueTeam: json['rescueTeam'] != null
          ? RescueTeamInfo.fromJson(json['rescueTeam'] as Map<String, dynamic>)
          : json['rescue_team'] != null
          ? RescueTeamInfo.fromJson(json['rescue_team'] as Map<String, dynamic>)
          : json['organization'] != null
          ? RescueTeamInfo.fromJson({
              ...json['organization'] as Map<String, dynamic>,
              'teamId': (json['organization'] as Map<String, dynamic>)['organizationId'],
              'teamName': (json['organization'] as Map<String, dynamic>)['organizationName'],
            })
          : null,
    );
  }
}
