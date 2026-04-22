import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Admin-only app bar: dark red background, optional drawer button and subtitle.
/// Use as [Scaffold.appBar] on all admin screens.
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showDrawerButton;
  final bool automaticallyImplyLeading;
  final bool centerTitle;

  static const Color _adminBarColor = Color(0xFF8B0000); // Dark red

  const AdminAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showDrawerButton = false,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    Widget? effectiveLeading = leading;
    if (showDrawerButton) {
      effectiveLeading = IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(context).openDrawer(),
      );
    }

    return AppBar(
      title: subtitle != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PremiumAppTheme.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle!,
                  style: PremiumAppTheme.bodySmall.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: PremiumAppTheme.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
      backgroundColor: _adminBarColor,
      elevation: 0,
      centerTitle: effectiveLeading == null ? true : centerTitle,
      leading: effectiveLeading,
      automaticallyImplyLeading: effectiveLeading != null
          ? false
          : automaticallyImplyLeading,
      actions: actions,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
    );
  }
}
