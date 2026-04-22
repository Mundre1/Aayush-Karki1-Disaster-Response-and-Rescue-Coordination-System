class CampaignModel {
  final int id;
  final int creatorId;
  final String title;
  final String description;
  final double targetAmount;
  final double raisedAmount;
  final String? imageUrl;
  final String status;
  final DateTime createdAt;
  final String? creatorName;

  CampaignModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.raisedAmount,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    this.creatorName,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['campaignId'] ?? 0,
      creatorId: json['creatorId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetAmount: double.tryParse(json['targetAmount']?.toString() ?? '0') ?? 0.0,
      raisedAmount: double.tryParse(json['raisedAmount']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      creatorName: json['creator']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaignId': id,
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'raisedAmount': raisedAmount,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return (raisedAmount / targetAmount).clamp(0.0, 1.0);
  }
}
