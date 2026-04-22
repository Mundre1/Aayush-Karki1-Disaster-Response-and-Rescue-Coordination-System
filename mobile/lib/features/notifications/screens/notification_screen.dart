import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notification_provider.dart';
import '../models/notification_model.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: PremiumAppBar(
            title: 'Notifications',
            actions: [
              if (provider.notifications.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Mark all as read',
                  onPressed: () {
                    provider.markAllAsRead();
                  },
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => provider.loadNotifications(refresh: true),
            child: provider.isLoading && provider.notifications.isEmpty
                ? PremiumWidgets.loadingIndicator(message: 'Loading notifications...')
                : provider.errorMessage != null && provider.notifications.isEmpty
                ? PremiumWidgets.emptyState(
                    title: 'Error loading notifications',
                    message: provider.errorMessage!,
                    icon: Icons.error_outline,
                    buttonText: 'Retry',
                    onAction: () => provider.loadNotifications(refresh: true),
                  )
                : provider.notifications.isEmpty
                ? PremiumWidgets.emptyState(
                    title: 'No notifications',
                    message: 'You have no notifications at the moment.',
                    icon: Icons.notifications_none,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = provider.notifications[index];
                      return _buildNotificationItem(context, notification, provider);
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification, NotificationProvider provider) {
    final bool isRead = notification.isRead;

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          provider.markAsRead(notification.notificationId);
        }
        if (notification.incidentId != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.incidentDetails,
            arguments: {'incidentId': notification.incidentId}
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isRead ? PremiumAppTheme.surface : PremiumAppTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? PremiumAppTheme.border : PremiumAppTheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: isRead ? null : [
            BoxShadow(
              color: PremiumAppTheme.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(notification.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getTitle(notification),
                          style: PremiumAppTheme.labelLarge.copyWith(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            color: isRead ? PremiumAppTheme.textPrimary : PremiumAppTheme.primary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: PremiumAppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: PremiumAppTheme.bodySmall.copyWith(
                      color: PremiumAppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(notification.createdAt),
                    style: PremiumAppTheme.labelSmall.copyWith(
                      color: PremiumAppTheme.textDisabled,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'incident_status_changed':
        iconData = Icons.info_outline;
        color = PremiumAppTheme.info;
        break;
      case 'new_incident':
        iconData = Icons.warning_amber_rounded;
        color = PremiumAppTheme.warning;
        break;
      case 'mission_assigned':
        iconData = Icons.assignment_outlined;
        color = PremiumAppTheme.primary;
        break;
      case 'mission_status_changed':
        iconData = Icons.task_alt;
        color = PremiumAppTheme.success;
        break;
      default:
        iconData = Icons.notifications_outlined;
        color = PremiumAppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  String _getTitle(NotificationModel notification) {
    switch (notification.type) {
      case 'incident_status_changed':
        return 'Incident Update';
      case 'new_incident':
        return 'New Incident';
      case 'mission_assigned':
        return 'Mission Assigned';
      case 'mission_status_changed':
        return 'Mission Update';
      default:
        return 'Notification';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

