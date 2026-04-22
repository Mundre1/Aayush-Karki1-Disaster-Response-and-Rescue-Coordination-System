import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin/admin_provider.dart';
import '../../admin/widgets/admin_drawer.dart';
import '../../notifications/notification_provider.dart';
import '../../notifications/widgets/notification_badge.dart';
import '../../admin/screens/admin_campaign_management_screen.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/admin_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connectivity_banner.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadDashboardStats();
      context.read<NotificationProvider>().updateUnreadCount();
    });
  }

  String _formatLastUpdated(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours} hr ago';
    return 'Updated ${diff.inDays} day(s) ago';
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AdminAppBar(
        title: 'Dashboard',
        subtitle: 'Control Center',
        showDrawerButton: true,
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => adminProvider.loadDashboardStats(),
          ),
        ],
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.dashboard),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => adminProvider.loadDashboardStats(),
              child: adminProvider.isLoadingStats
                  ? PremiumWidgets.loadingIndicator(message: 'Loading dashboard...')
                  : adminProvider.statsError != null
                  ? _buildErrorState(adminProvider)
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeroSection(adminProvider)),
                        SliverToBoxAdapter(child: _buildKPISection(adminProvider)),
                        SliverToBoxAdapter(
                          child: _buildQuickActionsSection(context, adminProvider),
                        ),
                        SliverToBoxAdapter(
                          child: _buildRecentActivitySection(adminProvider),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AdminProvider adminProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: PremiumAppTheme.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              adminProvider.statsError!,
              style: PremiumAppTheme.bodyMedium.copyWith(
                color: PremiumAppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PremiumWidgets.premiumButton(
              text: 'Retry',
              onPressed: () => adminProvider.loadDashboardStats(),
              icon: Icons.refresh,
              backgroundColor: PremiumAppTheme.emergencyDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(AdminProvider adminProvider) {
    final lastUpdated = adminProvider.lastStatsUpdated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF8B0000), // Solid Premium Maroon
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disaster Response',
                      style: PremiumAppTheme.headlineMedium.copyWith(
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
                  ],
                ),
              ),
            ],
          ),
          if (lastUpdated != null) ...[
            const SizedBox(height: 16),
            Text(
              _formatLastUpdated(lastUpdated),
              style: PremiumAppTheme.bodySmall.copyWith(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKPISection(AdminProvider adminProvider) {
    final stats = adminProvider.dashboardStats ?? {};
    final totalIncidents = stats['totalIncidents'] ?? 0;
    final pendingIncidents = stats['pendingIncidents'] ?? 0;
    final activeMissions = stats['activeMissions'] ?? 0;
    final totalVolunteers = stats['totalVolunteers'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key metrics',
            style: PremiumAppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  context,
                  'Total Incidents',
                  totalIncidents.toString(),
                  Icons.warning_amber_rounded,
                  Colors.orange,
                  pendingIncidents > 0
                      ? '$pendingIncidents need attention'
                      : null,
                  () => Navigator.pushNamed(context, AppRoutes.adminIncidents),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  context,
                  'Pending',
                  pendingIncidents.toString(),
                  Icons.pending_actions_rounded,
                  Colors.red,
                  'Require action',
                  () => Navigator.pushNamed(context, AppRoutes.adminIncidents),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  context,
                  'Active Missions',
                  activeMissions.toString(),
                  Icons.assignment_rounded,
                  Colors.blue,
                  null,
                  null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  context,
                  'Volunteers',
                  totalVolunteers.toString(),
                  Icons.people_rounded,
                  Colors.green,
                  null,
                  () => Navigator.pushNamed(context, AppRoutes.adminVolunteers),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
    String? subtitle,
    VoidCallback? onTap,
  ) {
    return PremiumWidgets.premiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 28),
              Text(
                value,
                style: PremiumAppTheme.headlineMedium.copyWith(
                  color: const Color(0xFF8B0000),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: PremiumAppTheme.titleSmall.copyWith(
              color: PremiumAppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: PremiumAppTheme.bodySmall.copyWith(
                color: PremiumAppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    AdminProvider adminProvider,
  ) {
    final stats = adminProvider.dashboardStats ?? {};
    final totalIncidents = stats['totalIncidents'] ?? 0;
    final totalVolunteers = stats['totalVolunteers'] ?? 0;
    final teams = adminProvider.rescueTeams;
    final teamCount = teams.isEmpty ? null : teams.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: PremiumAppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'Incidents',
                  '$totalIncidents total',
                  Icons.list_alt_rounded,
                  Colors.blue,
                  () => Navigator.pushNamed(context, AppRoutes.adminIncidents),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  'Volunteers',
                  totalVolunteers > 0 ? '$totalVolunteers approved' : null,
                  Icons.people_outline_rounded,
                  Colors.green,
                  () => Navigator.pushNamed(context, AppRoutes.adminVolunteers),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'Rescue Teams',
                  teamCount != null ? '$teamCount teams' : null,
                  Icons.groups_rounded,
                  Colors.purple,
                  () =>
                      Navigator.pushNamed(context, AppRoutes.adminRescueTeams),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  'Campaigns',
                  'Pending requests',
                  Icons.campaign_rounded,
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminCampaignManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'Reports',
                  'Coming soon',
                  Icons.analytics_rounded,
                  Colors.teal,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reports coming soon')),
                    );
                  },
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String? subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return PremiumWidgets.premiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: PremiumAppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: PremiumAppTheme.bodySmall.copyWith(
                color: PremiumAppTheme.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(AdminProvider adminProvider) {
    final recentIncidents = adminProvider.recentIncidents;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent activity',
                style: PremiumAppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.adminIncidents);
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentIncidents.isEmpty)
            PremiumWidgets.emptyState(
              title: 'No recent incidents',
              message: 'No incidents have been reported recently.',
              icon: Icons.inbox_rounded,
            )
          else
            ...recentIncidents.map(
              (incident) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumWidgets.incidentCard(
                  title: incident.title,
                  description: incident.description,
                  location: incident.location?.address ?? 'Unknown location',
                  status: incident.status,
                  severity: incident.severity,
                  imageUrl: incident.imageUrl,
                  reportedAt: incident.reportedAt,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.incidentDetails,
                      arguments: {'incidentId': incident.incidentId},
                    );
                  },
                  actions: [
                    PremiumWidgets.premiumButton(
                      text: 'Manage',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.adminIncidents,
                          arguments: {'incidentId': incident.incidentId},
                        );
                      },
                      width: 100,
                      height: 36,
                      backgroundColor: const Color(0xFF8B0000),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

