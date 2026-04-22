import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumWidgets {
  // Premium Button Component
  static Widget premiumButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isEmergency = false,
    IconData? icon,
    double? width,
    double? height,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final bgColor = isEmergency
        ? PremiumAppTheme.emergency
        : (backgroundColor ?? PremiumAppTheme.primary);

    final fgColor = textColor ?? Colors.white;

    return SizedBox(
      width: width,
      height: height ?? 56,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : (width ?? 200);
          final showLabel = maxWidth >= 88;

          return ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              elevation: isEmergency ? 4 : 2,
              shadowColor: bgColor.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 8),
            ),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) Icon(icon, size: 18),
                      if (icon != null && showLabel) const SizedBox(width: 8),
                      if (showLabel)
                        Flexible(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PremiumAppTheme.labelLarge.copyWith(
                              color: fgColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // Premium Card Component
  static Widget premiumCard({
    required Widget child,
    double? width,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    bool hasShadow = true,
    double borderRadius = 16,
    VoidCallback? onTap,
  }) {
    final card = Container(
      width: width,
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? PremiumAppTheme.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: PremiumAppTheme.border, width: 0.5),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
  }

  // Premium Status Indicator
  static Widget statusIndicator({
    required String status,
    required String text,
    double size = 12,
  }) {
    final color = PremiumAppTheme.getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size / 2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: PremiumAppTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Premium Incident Card
  static Widget incidentCard({
    required String title,
    required String description,
    required String location,
    required String status,
    required String severity,
    String? imageUrl,
    DateTime? reportedAt,
    VoidCallback? onTap,
    List<Widget>? actions,
  }) {
    final severityColor = PremiumAppTheme.getSeverityColor(severity);

    return premiumCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with severity indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: PremiumAppTheme.headlineSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: severityColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: PremiumAppTheme.labelSmall.copyWith(
                    color: severityColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: PremiumAppTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // Location and Status row
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: PremiumAppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: PremiumAppTheme.bodySmall.copyWith(
                    color: PremiumAppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              statusIndicator(status: status, text: status),
            ],
          ),

          if (reportedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Reported ${_formatTimeAgo(reportedAt)}',
              style: PremiumAppTheme.bodySmall.copyWith(
                color: PremiumAppTheme.textDisabled,
              ),
            ),
          ],

          if (actions != null && actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ],
        ],
      ),
    );
  }

  // Premium Loading Indicator
  static Widget loadingIndicator({String? message, double size = 40}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                PremiumAppTheme.primary,
              ),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: PremiumAppTheme.bodyMedium.copyWith(
                color: PremiumAppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Premium Empty State
  static Widget emptyState({
    required String title,
    required String message,
    IconData? icon,
    String? buttonText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 80, color: PremiumAppTheme.textDisabled),
              const SizedBox(height: 24),
            ],
            Text(
              title,
              style: PremiumAppTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: PremiumAppTheme.bodyMedium.copyWith(
                color: PremiumAppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 32),
              premiumButton(
                text: buttonText,
                onPressed: onAction,
                icon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Premium Stat Card
  static Widget statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PremiumAppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumAppTheme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: PremiumAppTheme.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: PremiumAppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: PremiumAppTheme.bodySmall.copyWith(
              color: PremiumAppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Modern List Item
  static Widget modernListItem({
    required String title,
    required String subtitle,
    required Widget leading,
    Widget? trailing,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? PremiumAppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PremiumAppTheme.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: leading,
        title: Text(
          title,
          style: PremiumAppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: PremiumAppTheme.bodySmall.copyWith(
            color: PremiumAppTheme.textSecondary,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  // Section Header
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PremiumAppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: PremiumAppTheme.labelSmall.copyWith(
                    color: PremiumAppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  // Modern Profile Header
  static Widget profileHeader({
    required String title,
    required String subtitle,
    required Widget avatar,
    required List<Widget> stats,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: BoxDecoration(
        color: backgroundColor ?? PremiumAppTheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PremiumAppTheme.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: PremiumAppTheme.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: stats,
          ),
        ],
      ),
    );
  }

  // Helper method for time formatting
  static String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}

