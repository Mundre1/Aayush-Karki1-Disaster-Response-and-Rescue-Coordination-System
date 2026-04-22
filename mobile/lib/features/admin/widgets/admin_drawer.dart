import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';

/// Drawer used on all admin screens for section switching.
/// Pass [currentRoute] to highlight the active section.
class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  static const Color _headerColor = Color(0xFF8B0000);

  const AdminDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: _headerColor),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Disaster Response',
                    style: PremiumAppTheme.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Admin Control Center',
                    style: PremiumAppTheme.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: PremiumAppTheme.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerTile(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: AppRoutes.dashboard,
                  currentRoute: currentRoute,
                  onTap: () => _navigateAndClose(context, AppRoutes.dashboard),
                ),
                _DrawerTile(
                  icon: Icons.list_alt_rounded,
                  label: 'Incidents',
                  route: AppRoutes.adminIncidents,
                  currentRoute: currentRoute,
                  onTap: () =>
                      _navigateAndClose(context, AppRoutes.adminIncidents),
                ),
                _DrawerTile(
                  icon: Icons.people_outline_rounded,
                  label: 'Volunteers',
                  route: AppRoutes.adminVolunteers,
                  currentRoute: currentRoute,
                  onTap: () =>
                      _navigateAndClose(context, AppRoutes.adminVolunteers),
                ),
                _DrawerTile(
                  icon: Icons.groups_rounded,
                  label: 'Rescue Teams',
                  route: AppRoutes.adminRescueTeams,
                  currentRoute: currentRoute,
                  onTap: () =>
                      _navigateAndClose(context, AppRoutes.adminRescueTeams),
                ),
                _DrawerTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Campaign management',
                  route: AppRoutes.adminCampaignManagement,
                  currentRoute: currentRoute,
                  onTap: () => _navigateAndClose(
                      context, AppRoutes.adminCampaignManagement),
                ),
                _DrawerTile(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Donation management',
                  route: AppRoutes.adminPendingBankDonations,
                  currentRoute: currentRoute,
                  onTap: () => _navigateAndClose(
                      context, AppRoutes.adminPendingBankDonations),
                ),
                _DrawerTile(
                  icon: Icons.how_to_reg_outlined,
                  label: 'Mission requests',
                  route: AppRoutes.adminMissionRequests,
                  currentRoute: currentRoute,
                  onTap: () =>
                      _navigateAndClose(context, AppRoutes.adminMissionRequests),
                ),
                _DrawerTile(
                  icon: Icons.approval_rounded,
                  label: 'Responder approvals',
                  route: AppRoutes.adminResponderApprovals,
                  currentRoute: currentRoute,
                  onTap: () => _navigateAndClose(
                    context,
                    AppRoutes.adminResponderApprovals,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.logout_rounded,
              color: PremiumAppTheme.textSecondary,
            ),
            title: Text(
              'Logout',
              style: PremiumAppTheme.titleMedium.copyWith(
                color: PremiumAppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _navigateAndClose(BuildContext context, String route) {
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacementNamed(route);
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? const Color(0xFF8B0000)
            : PremiumAppTheme.textSecondary,
      ),
      title: Text(
        label,
        style: PremiumAppTheme.titleMedium.copyWith(
          color: isSelected
              ? const Color(0xFF8B0000)
              : PremiumAppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF8B0000).withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}

