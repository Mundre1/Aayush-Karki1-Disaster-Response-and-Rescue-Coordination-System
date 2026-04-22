class DonationModel {
  final int id;
  final int? campaignId;
  final String? campaignTitle;
  final String? donorName;
  final String? donorEmail;
  final double amount;
  final String? paymentMethod;
  final String? transactionId;
  final String? bankReference;
  final String status;
  final DateTime createdAt;

  DonationModel({
    required this.id,
    this.campaignId,
    this.campaignTitle,
    this.donorName,
    this.donorEmail,
    required this.amount,
    this.paymentMethod,
    this.transactionId,
    this.bankReference,
    required this.status,
    required this.createdAt,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    final campaign = json['campaign'];
    return DonationModel(
      id: json['donationId'] ?? json['id'],
      campaignId: json['campaignId'] ?? json['campaign_id'],
      campaignTitle: campaign is Map ? campaign['title'] as String? : null,
      donorName: json['donorName'],
      donorEmail: json['donorEmail'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paymentMethod: json['paymentMethod'],
      transactionId: json['transactionId'] ?? json['transaction_id'],
      bankReference: json['bankReference'] ?? json['bank_reference'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'donationId': id,
      'campaignId': campaignId,
      'campaignTitle': campaignTitle,
      'donorName': donorName,
      'donorEmail': donorEmail,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'bankReference': bankReference,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
