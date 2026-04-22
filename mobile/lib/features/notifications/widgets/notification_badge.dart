import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notification_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

class NotificationBadge extends StatelessWidget {
  final Color? color;

  const NotificationBadge({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: color ?? Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.notifications);
              },
            ),
            if (provider.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: PremiumAppTheme.emergency,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      provider.unreadCount > 99 ? '99+' : provider.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
