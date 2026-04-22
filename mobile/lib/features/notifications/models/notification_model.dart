class NotificationModel {
  final int notificationId;
  final int userId;
  final int? incidentId;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final NotificationRelatedIncident? incident;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    this.incidentId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.incident,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] ?? json['notification_id'],
      userId: json['userId'] ?? json['user_id'],
      incidentId: json['incidentId'] ?? json['incident_id'],
      type: json['type'],
      message: json['message'],
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      incident: json['incident'] != null
          ? NotificationRelatedIncident.fromJson(json['incident'])
          : null,
    );
  }
}

class NotificationRelatedIncident {
  final int incidentId;
  final String title;
  final String status;

  NotificationRelatedIncident({
    required this.incidentId,
    required this.title,
    required this.status,
  });

  factory NotificationRelatedIncident.fromJson(Map<String, dynamic> json) {
    return NotificationRelatedIncident(
      incidentId: json['incidentId'] ?? json['incident_id'],
      title: json['title'],
      status: json['status'],
    );
  }
}
