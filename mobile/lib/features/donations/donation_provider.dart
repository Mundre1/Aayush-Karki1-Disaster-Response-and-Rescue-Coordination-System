import 'package:flutter/material.dart';
import 'models/donation_model.dart';
import 'services/donation_service.dart';

class DonationProvider extends ChangeNotifier {
  final DonationService _donationService = DonationService();

  List<DonationModel> _myDonations = [];
  DonationModel? _activeDonation;
  bool _isLoading = false;
  String? _error;

  List<DonationModel> get myDonations => _myDonations;
  DonationModel? get activeDonation => _activeDonation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> createDonation(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _donationService.createDonation(data);
      // After successful donation, we can reload the list if it was already loaded
      // or just leave it for the next time the user visits the history screen.
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<DonationModel> initiateEsewaDonation(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final donation = await _donationService.initiateEsewaDonation(data);
      _activeDonation = donation;
      _error = null;
      notifyListeners();
      return donation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<DonationModel> confirmEsewaDonation(
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    try {
      final updatedDonation = await _donationService.confirmEsewaDonation(data);
      _activeDonation = updatedDonation;
      await loadMyDonations();
      _error = null;
      return updatedDonation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> failEsewaDonation(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final updatedDonation = await _donationService.failEsewaDonation(data);
      _activeDonation = updatedDonation;
      await loadMyDonations();
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyDonations() async {
    _setLoading(true);
    try {
      _myDonations = await _donationService.getMyDonations();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _myDonations = [];
    } finally {
      _setLoading(false);
      notifyListeners();
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
