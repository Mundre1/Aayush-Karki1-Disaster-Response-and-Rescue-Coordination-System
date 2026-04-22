import 'package:disaster_response_mobile/features/donations/models/donation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UT-DART-02 DonationModel serialization round-trip', () {
    print('[UT-DART-02] Starting DonationModel round-trip test');
    final source = {
      'donationId': 101,
      'campaignId': 7,
      'campaign': {'title': 'Relief Drive'},
      'donorName': 'Test Donor',
      'donorEmail': 'donor@example.com',
      'amount': '2500.5',
      'paymentMethod': 'BANK',
      'transactionId': 'TXN-001',
      'bankReference': 'REF-001',
      'status': 'PENDING',
      'createdAt': '2026-04-21T10:30:00.000Z',
    };

    final model = DonationModel.fromJson(source);
    final encoded = model.toJson();

    expect(model.id, 101);
    expect(model.amount, 2500.5);
    expect(model.campaignTitle, 'Relief Drive');
    expect(encoded['donationId'], 101);
    expect(encoded['status'], 'PENDING');
    print('[UT-DART-02] Completed successfully with no errors ${model.id} ${model.amount} ${model.campaignTitle} ${encoded['donationId']} ${encoded['status']}');
  });
}
