import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../incidents/incident_provider.dart';
import '../../volunteers/volunteer_provider.dart';
import '../../donations/donation_provider.dart';
import '../../notifications/notification_provider.dart';
import '../../notifications/widgets/notification_badge.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../widgets/profile_screen_shared.dart';
import '../../../core/widgets/connectivity_banner.dart';

String _missionRequestLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Awaiting admin decision';
    case 'approved':
      return 'Approved';
    case 'rejected':
      return 'Not approved';
    default:
      return status;
  }
}

Future<bool?> _showRegisterVolunteer(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Register as volunteer'),
      content: const Text(
        'Register with the app to join missions. You will need admin approval.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
          ),
          child: const Text('Register'),
        ),
      ],
    ),
  );
}

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<IncidentProvider>(context, listen: false).loadIncidents();
      Provider.of<IncidentProvider>(context, listen: false).loadMyIncidents();
      Provider.of<DonationProvider>(context, listen: false).loadMyDonations();
      Provider.of<VolunteerProvider>(context, listen: false).loadProfile();
      Provider.of<VolunteerProvider>(context, listen: false).loadMissionRequests();
      Provider.of<NotificationProvider>(context, listen: false).updateUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                VolunteerHomeTab(
                  onSwitchToTab: (index) => setState(() => _selectedIndex = index),
                ),
                const VolunteerIncidentsTab(),
                ProfileScreenShared(
                  accentColor: Colors.green.shade700,
                  appBarTitle: 'Profile',
                  extraTiles: [
                    Consumer<VolunteerProvider>(
                      builder: (context, vp, _) {
                        return ListTile(
                          leading: Icon(
                            Icons.handshake,
                            color: Colors.green.shade700,
                          ),
                          title: const Text('Volunteer profile'),
                          subtitle: Text(
                            vp.profile != null
                                ? (vp.isApproved
                                      ? 'Approved • ${vp.profile!.availability ?? "—"}'
                                      : 'Pending approval')
                                : 'Register as volunteer to join missions',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            if (vp.profile == null) {
                              final result = await _showRegisterVolunteer(context);
                              if (result == true && context.mounted) {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                                final res = await vp.register();
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                res['message'] as String? ?? 'Done',
                                    ),
                              backgroundColor: res['success'] == true
                                  ? PremiumAppTheme.success
                                  : PremiumAppTheme.emergency,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPremiumBottomNav(),
    );
  }

  Widget _buildPremiumBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PremiumAppTheme.surface, PremiumAppTheme.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.warning_amber_rounded, 'Incidents', 1),
              _buildNavItem(Icons.person_rounded, 'Profile', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.shade700.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.green.shade700
                  : PremiumAppTheme.textDisabled,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: PremiumAppTheme.labelSmall.copyWith(
                color: isSelected
                    ? Colors.green.shade700
                    : PremiumAppTheme.textDisabled,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VolunteerHomeTab extends StatelessWidget {
  const VolunteerHomeTab({super.key, this.onSwitchToTab});
  final void Function(int index)? onSwitchToTab;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final incidentProvider =
            Provider.of<IncidentProvider>(context, listen: false);
        final volunteerProvider =
            Provider.of<VolunteerProvider>(context, listen: false);
        await incidentProvider.loadIncidents();
        await volunteerProvider.loadProfile();
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            actions: [
              IconButton(
                icon: const Icon(Icons.map_rounded, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.map),
              ),
              const NotificationBadge(),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Volunteer Dashboard'),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade400],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.handshake_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VolunteerStatusCard(),
                  const SizedBox(height: 24),
                  Consumer<IncidentProvider>(
                    builder: (context, incidentProvider, _) {
                      return _VolunteerStatsSection(provider: incidentProvider);
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<IncidentProvider>(
                    builder: (context, incidentProvider, _) {
                      return _VolunteerRecentIncidents(
                        provider: incidentProvider,
                        onViewAll: () => onSwitchToTab?.call(1),
                      );
                    },
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

class _VolunteerStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<VolunteerProvider>(
      builder: (context, vp, _) {
        if (vp.isLoading && vp.profile == null) {
          return PremiumWidgets.premiumCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: PremiumWidgets.loadingIndicator(
                  message: 'Loading volunteer profile...',
                ),
              ),
            ),
          );
        }
        final profile = vp.profile;
        if (profile == null && vp.errorMessage != null) {
          return PremiumWidgets.premiumCard(
            child: Column(
              children: [
                const Text(
                  'Not registered as volunteer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  vp.errorMessage!,
                  style: PremiumAppTheme.bodySmall.copyWith(
                    color: PremiumAppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Register as volunteer in Profile to see status and join missions.',
                  style: PremiumAppTheme.bodySmall.copyWith(
                    color: PremiumAppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        if (profile == null) {
          return const SizedBox.shrink();
        }
        return PremiumWidgets.premiumCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (profile.isApproved
                              ? Colors.green
                              : PremiumAppTheme.warning)
                          .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  profile.isApproved ? Icons.verified : Icons.pending,
                  color: profile.isApproved
                      ? Colors.green.shade700
                      : PremiumAppTheme.warning,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.isApproved
                          ? 'Approved Volunteer'
                          : 'Pending Approval',
                      style: PremiumAppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (profile.skills != null &&
                        profile.skills!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.skills!,
                        style: PremiumAppTheme.bodySmall.copyWith(
                          color: PremiumAppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Availability: ${profile.availability ?? "—"}',
                      style: PremiumAppTheme.labelSmall.copyWith(
                        color: PremiumAppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VolunteerStatsSection extends StatelessWidget {
  const _VolunteerStatsSection({required this.provider});
  final IncidentProvider provider;

  @override
  Widget build(BuildContext context) {
    final stats = {
      'total': provider.incidents.length,
      'pending': provider.incidents.where((i) => i.status == 'pending').length,
      'assigned': provider.incidents
          .where((i) => i.status == 'assigned')
          .length,
      'resolved': provider.incidents
          .where((i) => i.status == 'resolved')
          .length,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Incidents Overview', style: PremiumAppTheme.headlineSmall),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _statCard(
              'Total',
              stats['total'].toString(),
              Icons.description_outlined,
              PremiumAppTheme.primary,
            ),
            _statCard(
              'Pending',
              stats['pending'].toString(),
              Icons.pending_actions_outlined,
              PremiumAppTheme.warning,
            ),
            _statCard(
              'Active',
              stats['assigned'].toString(),
              Icons.assignment_ind_outlined,
              PremiumAppTheme.info,
            ),
            _statCard(
              'Resolved',
              stats['resolved'].toString(),
              Icons.check_circle_outline,
              PremiumAppTheme.success,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return PremiumWidgets.premiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: PremiumAppTheme.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: PremiumAppTheme.bodySmall.copyWith(
              color: PremiumAppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VolunteerRecentIncidents extends StatelessWidget {
  const _VolunteerRecentIncidents({
    required this.provider,
    required this.onViewAll,
  });
  final IncidentProvider provider;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Incidents', style: PremiumAppTheme.headlineSmall),
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'View All',
                style: PremiumAppTheme.labelMedium.copyWith(
                  color: PremiumAppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.incidents.isEmpty)
          PremiumWidgets.emptyState(
            title: 'No incidents yet',
            message: 'Incidents will appear here when reported',
            icon: Icons.inbox_outlined,
          )
        else
          ...provider.incidents.take(3).map((incident) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumWidgets.incidentCard(
                title: incident.title,
                description: incident.description,
                location: incident.location?.address ?? 'Unknown location',
                status: incident.status,
                severity: incident.severity,
                reportedAt: incident.reportedAt,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.incidentDetails,
                    arguments: {'incidentId': incident.incidentId},
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}

class VolunteerIncidentsTab extends StatelessWidget {
  const VolunteerIncidentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<IncidentProvider, VolunteerProvider>(
      builder: (context, incidentProvider, volunteerProvider, _) {
        return Scaffold(
          appBar: PremiumAppBar(
            title: 'Available Incidents',
            actions: [
              const NotificationBadge(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  incidentProvider.loadIncidents();
                  volunteerProvider.loadProfile();
                  volunteerProvider.loadMissionRequests();
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await incidentProvider.loadIncidents();
              await volunteerProvider.loadProfile();
              await volunteerProvider.loadMissionRequests();
            },
            child: incidentProvider.isLoading
                ? PremiumWidgets.loadingIndicator(
                    message: 'Loading incidents...',
                  )
                : incidentProvider.errorMessage != null
                ? PremiumWidgets.emptyState(
                    title: 'Error loading incidents',
                    message: incidentProvider.errorMessage!,
                    icon: Icons.error_outline,
                    buttonText: 'Retry',
                    onAction: () => incidentProvider.loadIncidents(),
                  )
                : (incidentProvider.incidents.isEmpty && incidentProvider.pendingIncidents.isEmpty)
                ? PremiumWidgets.emptyState(
                    title: 'No incidents reported',
                    message: 'Incidents in your area will appear here',
                    icon: Icons.warning_amber_outlined,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (volunteerProvider.hasProfile &&
                          !volunteerProvider.isApproved)
                        Card(
                          color: Colors.amber.shade50,
                          child: const ListTile(
                            leading: Icon(Icons.schedule, color: Colors.amber),
                            title: Text('Volunteer approval pending'),
                            subtitle: Text(
                              'An administrator must approve your registration before you can request missions.',
                            ),
                          ),
                        ),
                      if (volunteerProvider.hasProfile &&
                          !volunteerProvider.isApproved)
                        const SizedBox(height: 12),
                      if (volunteerProvider.missionRequests.isNotEmpty) ...[
                        Text(
                          'Your mission requests',
                          style: PremiumAppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...volunteerProvider.missionRequests.map((r) {
                          final st = r['status']?.toString() ?? '';
                          final mid = r['missionId'] ?? r['mission_id'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text('Mission #$mid'),
                              subtitle: Text(_missionRequestLabel(st)),
                              trailing: Icon(
                                st == 'approved'
                                    ? Icons.check_circle
                                    : st == 'rejected'
                                        ? Icons.cancel
                                        : Icons.hourglass_empty,
                                color: st == 'approved'
                                    ? Colors.green
                                    : st == 'rejected'
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                          );
                        }),
                        const Divider(height: 24),
                      ],
                      if (incidentProvider.pendingIncidents.isNotEmpty) ...[
                        Text(
                          'Pending Sync (${incidentProvider.pendingIncidents.length})',
                          style: PremiumAppTheme.labelMedium.copyWith(
                            color: PremiumAppTheme.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...incidentProvider.pendingIncidents.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Opacity(
                              opacity: 0.7,
                              child: PremiumWidgets.incidentCard(
                                title: item.data['title'] ?? 'New Incident',
                                description: item.data['description'] ?? '',
                                location: item.data['address'] ?? 'Detecting...',
                                status: 'Pending Sync',
                                severity: item.data['severity'] ?? 'low',
                                reportedAt: item.createdAt,
                                onTap: null,
                              ),
                            ),
                          );
                        }),
                        const Divider(),
                        const SizedBox(height: 8),
                      ],
                      ...incidentProvider.incidents.map((incident) {
                        final hasMission =
                            incident.missionIds != null &&
                            incident.missionIds!.isNotEmpty;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PremiumWidgets.incidentCard(
                                title: incident.title,
                                description: incident.description,
                                location:
                                    incident.location?.address ??
                                    'Unknown location',
                                status: incident.status,
                                severity: incident.severity,
                                reportedAt: incident.reportedAt,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.incidentDetails,
                                    arguments: {
                                      'incidentId': incident.incidentId,
                                    },
                                  );
                                },
                              ),
                              if (hasMission && volunteerProvider.isApproved) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 40,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                                      final missionId =
                                          incident.missionIds!.first;
                                      final result = await volunteerProvider
                                          .requestToJoinMission(missionId);
                                      scaffoldMessenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['message'] as String? ??
                                                (result['success'] == true
                                                    ? 'Request submitted'
                                                    : 'Failed'),
                                          ),
                                          backgroundColor:
                                              result['success'] == true
                                              ? PremiumAppTheme.success
                                              : PremiumAppTheme.emergency,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.handshake, size: 20),
                                    label: const Text('Request to join mission'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green.shade700,
                                      side: BorderSide(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

