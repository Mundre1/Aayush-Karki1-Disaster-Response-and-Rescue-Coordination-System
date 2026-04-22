import '../../../core/services/api_service.dart';
import '../../../core/config/app_config.dart';
import '../models/campaign_model.dart';

class CampaignService {
  final ApiService _apiService = ApiService();

  Future<List<CampaignModel>> getCampaigns({String? status, int? creatorId}) async {
    final queryParameters = <String, dynamic>{};
    if (status != null) queryParameters['status'] = status;
    if (creatorId != null) queryParameters['creatorId'] = creatorId;

    final response = await _apiService.get(
      AppConfig.campaignsEndpoint,
      queryParams: queryParameters,
    );

    final raw = response.data['data'] ?? response.data['campaigns'];
    if (raw == null) return [];
    final List<dynamic> list = raw is List ? raw : [];
    return list.map((json) => CampaignModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<CampaignModel> requestCampaign(Map<String, dynamic> data) async {
    final response = await _apiService.post(
      '${AppConfig.campaignsEndpoint}/request',
      body: data,
    );
    final payload = response.data['data'] ?? response.data['campaign'];
    if (payload is! Map<String, dynamic>) {
      throw Exception('Invalid campaign response from server');
    }
    return CampaignModel.fromJson(payload);
  }

  Future<CampaignModel> updateCampaignStatus(int id, String status) async {
    final response = await _apiService.patch(
      AppConfig.campaignStatusUpdate(id),
      body: {'status': status},
    );
    final payload = response.data['data'] ?? response.data['campaign'];
    return CampaignModel.fromJson(payload);
  }

  Future<CampaignModel> getCampaignById(int id) async {
    final response = await _apiService.get(
      '${AppConfig.campaignsEndpoint}/$id',
    );
    final payload = response.data['data'] ?? response.data['campaign'];
    return CampaignModel.fromJson(payload);
  }
}
