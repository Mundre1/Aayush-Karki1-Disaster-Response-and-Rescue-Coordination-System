import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom app bar used throughout the app with consistent premium styling.
/// Use as [Scaffold.appBar].
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: PremiumAppTheme.titleLarge.copyWith(fontWeight: FontWeight.w600),
      ),
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      bottom: bottom,
      titleTextStyle: PremiumAppTheme.titleLarge.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
