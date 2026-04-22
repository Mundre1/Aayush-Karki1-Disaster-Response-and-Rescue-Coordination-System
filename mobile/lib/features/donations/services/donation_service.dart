import '../../../core/services/api_service.dart';
import '../../../core/config/app_config.dart';
import '../models/donation_model.dart';

class DonationService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getBankInfo() async {
    final response = await _apiService.get(AppConfig.donationsBankInfo);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<DonationModel> createDonation(Map<String, dynamic> data) async {
    final response = await _apiService.post(
      AppConfig.donationsEndpoint,
      body: data,
    );
    final payload = response.data['donation'] ?? response.data['data'];
    return DonationModel.fromJson(payload);
  }

  Future<List<DonationModel>> getMyDonations() async {
    final response = await _apiService.get(
      '${AppConfig.donationsEndpoint}/my',
    );

    final List<dynamic> data = response.data['donations'];
    return data.map((json) => DonationModel.fromJson(json)).toList();
  }

  Future<DonationModel> initiateEsewaDonation(Map<String, dynamic> data) async {
    final response = await _apiService.post(
      AppConfig.donationsEsewaInitiate,
      body: data,
    );
    final payload = response.data['donation'] ?? response.data['data'];
    return DonationModel.fromJson(payload);
  }

  Future<DonationModel> confirmEsewaDonation(Map<String, dynamic> data) async {
    final response = await _apiService.post(
      AppConfig.donationsEsewaConfirm,
      body: data,
    );
    final payload = response.data['donation'] ?? response.data['data'];
    return DonationModel.fromJson(payload);
  }

  Future<DonationModel> failEsewaDonation(Map<String, dynamic> data) async {
    final response = await _apiService.post(
      AppConfig.donationsEsewaFail,
      body: data,
    );
    final payload = response.data['donation'] ?? response.data['data'];
    return DonationModel.fromJson(payload);
  }
}
