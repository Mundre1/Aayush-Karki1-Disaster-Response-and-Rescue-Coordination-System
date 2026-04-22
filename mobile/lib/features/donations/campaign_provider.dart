import 'package:flutter/material.dart';
import 'models/campaign_model.dart';
import 'services/campaign_service.dart';

class CampaignProvider extends ChangeNotifier {
  final CampaignService _campaignService = CampaignService();

  List<CampaignModel> _activeCampaigns = [];
  List<CampaignModel> _pendingCampaigns = [];
  List<CampaignModel> _myCampaigns = [];
  
  bool _isLoading = false;
  String? _error;

  List<CampaignModel> get activeCampaigns => _activeCampaigns;
  List<CampaignModel> get pendingCampaigns => _pendingCampaigns;
  List<CampaignModel> get myCampaigns => _myCampaigns;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadActiveCampaigns() async {
    _setLoading(true);
    try {
      _activeCampaigns = await _campaignService.getCampaigns(status: 'approved');
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingCampaigns() async {
    _setLoading(true);
    try {
      _pendingCampaigns = await _campaignService.getCampaigns(status: 'pending');
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyCampaignRequests(int userId) async {
    _setLoading(true);
    try {
      _myCampaigns = await _campaignService.getCampaigns(creatorId: userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> requestCampaign(String title, String description, double targetAmount) async {
    _setLoading(true);
    try {
      await _campaignService.requestCampaign({
        'title': title,
        'description': description,
        'targetAmount': targetAmount,
      });
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveCampaign(int id) async {
    _setLoading(true);
    try {
      await _campaignService.updateCampaignStatus(id, 'approved');
      await loadPendingCampaigns();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectCampaign(int id) async {
    _setLoading(true);
    try {
      await _campaignService.updateCampaignStatus(id, 'rejected');
      await loadPendingCampaigns();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
