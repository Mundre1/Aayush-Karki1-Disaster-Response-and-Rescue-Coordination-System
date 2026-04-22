import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOnline = true; // Assume online initially

  bool get isOnline => _isOnline;

  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // In connectivity_plus 6.x, it returns a list of results
    final bool hasConnection = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      debugPrint('🌐 Connectivity Changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
