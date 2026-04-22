class CommentModel {
  final int commentId;
  final String content;
  final int incidentId;
  final int userId;
  final String userName;
  final String userRole;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.content,
    required this.incidentId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId'] ?? json['comment_id'],
      content: json['content'],
      incidentId: json['incidentId'] ?? json['incident_id'],
      userId: json['userId'] ?? json['user_id'],
      userName: json['user']?['name'] ?? 'Unknown User',
      userRole: json['user']?['role']?['roleName'] ?? 'user',
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
    );
  }
}
