class IncidentUpdateEntry {
  final String status;
  final String? note;
  final String? imageUrl;
  final DateTime updatedAt;
  final String? userName;

  IncidentUpdateEntry({
    required this.status,
    this.note,
    this.imageUrl,
    required this.updatedAt,
    this.userName,
  });

  factory IncidentUpdateEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return IncidentUpdateEntry(
      status: json['status']?.toString() ?? '',
      note: json['note'] as String?,
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      updatedAt: DateTime.tryParse(
            json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      userName: user?['name'] as String?,
    );
  }
}
