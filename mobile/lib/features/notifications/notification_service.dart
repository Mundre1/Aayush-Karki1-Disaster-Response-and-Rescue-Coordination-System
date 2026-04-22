import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../../core/config/app_config.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/storage_service.dart';
import 'models/notification_model.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivity = ConnectivityService();
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    if (!_connectivity.isOnline) {
      final cached = _storageService.getCachedNotifications();
      return {
        'notifications': cached,
        'pagination': {'total': cached.length, 'page': 1, 'limit': limit}
      };
    }

    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (isRead != null) {
        queryParams['isRead'] = isRead;
      }

      final response = await _apiService.get(
        AppConfig.notificationsEndpoint,
        queryParams: queryParams,
      );

      final data = response.data;
      if (data != null && data['notifications'] != null) {
        final list = data['notifications'] as List<dynamic>;
        await _storageService.cacheNotifications(
          list.map((e) => e as Map<String, dynamic>).toList(),
        );
      }

      return data;
    } catch (e) {
      debugPrint('NotificationService getNotifications error: $e');
      final cached = _storageService.getCachedNotifications();
      return {
        'notifications': cached,
        'pagination': {'total': cached.length, 'page': 1, 'limit': limit}
      };
    }
  }

  Future<NotificationModel> markAsRead(int notificationId) async {
    final response = await _apiService.put(
      '${AppConfig.notificationsEndpoint}/$notificationId/read',
    );
    return NotificationModel.fromJson(response.data['notification']);
  }

  Future<void> markAllAsRead() async {
    await _apiService.put('${AppConfig.notificationsEndpoint}/read-all');
  }
}
