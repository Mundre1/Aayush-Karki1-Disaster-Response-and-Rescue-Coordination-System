import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../incidents/incident_provider.dart';
import '../../rescue_team/rescue_team_provider.dart';
import '../../donations/donation_provider.dart';
import '../../notifications/notification_provider.dart';
import '../../notifications/widgets/notification_badge.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../features/missions/models/mission_model.dart';
import '../widgets/profile_screen_shared.dart';
import '../../../core/widgets/connectivity_banner.dart';
import '../../../core/services/socket_service.dart';

class RescueTeamDashboardScreen extends StatefulWidget {
  const RescueTeamDashboardScreen({super.key});

  @override
  State<RescueTeamDashboardScreen> createState() =>
      _RescueTeamDashboardScreenState();
}

class _RescueTeamDashboardScreenState extends State<RescueTeamDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<IncidentProvider>(context, listen: false).loadIncidents();
      Provider.of<IncidentProvider>(context, listen: false).loadMyIncidents();
      Provider.of<DonationProvider>(context, listen: false).loadMyDonations();
      Provider.of<RescueTeamProvider>(context, listen: false).loadMissions();
      Provider.of<NotificationProvider>(context, listen: false).updateUnreadCount();
      
      // Listen for new missions
      SocketService().onMissionAssigned((data) {
        if (mounted) {
          _showMissionAssignmentAlert(data);
        }
      });
    });
  }

  void _showMissionAssignmentAlert(dynamic data) {
    try {
      final mission = MissionModel.fromJson(data);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.assignment_ind_rounded, color: PremiumAppTheme.primary),
              const SizedBox(width: 10),
              const Text('New Mission Assigned'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mission.incident?.title ?? 'Emergency Incident',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(mission.incident?.description ?? 'Please check mission details.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DISMISS'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.missionDetails,
                  arguments: {'mission': mission},
                );
              },
              child: const Text('VIEW DETAILS'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error showing mission alert: $e');
    }
  }

  @override
  void dispose() {
    SocketService().offMissionAssigned();
    super.dispose();
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
                RescueTeamHomeTab(
                  onSwitchToTab: (index) => setState(() => _selectedIndex = index),
                ),
                const RescueTeamIncidentsTab(),
                ProfileScreenShared(
                  accentColor: Colors.blue.shade700,
                  appBarTitle: 'Profile',
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
              _buildNavItem(Icons.assignment_rounded, 'Missions', 0),
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
    final blue = Colors.blue.shade700;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? blue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? blue : PremiumAppTheme.textDisabled,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: PremiumAppTheme.labelSmall.copyWith(
                color: isSelected ? blue : PremiumAppTheme.textDisabled,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RescueTeamHomeTab extends StatelessWidget {
  const RescueTeamHomeTab({super.key, this.onSwitchToTab});
  final void Function(int index)? onSwitchToTab;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final incidentProvider =
            Provider.of<IncidentProvider>(context, listen: false);
        final rescueTeamProvider =
            Provider.of<RescueTeamProvider>(context, listen: false);
        await incidentProvider.loadIncidents();
        await rescueTeamProvider.loadMissions();
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
              title: const Text('My Missions'),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_fire_department_rounded,
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
              child: Consumer<RescueTeamProvider>(
                builder: (context, rtp, _) {
                  if (rtp.isLoading && rtp.missions.isEmpty) {
                    return PremiumWidgets.premiumCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: PremiumWidgets.loadingIndicator(
                            message: 'Loading missions...',
                          ),
                        ),
                      ),
                    );
                  }
                  if (rtp.errorMessage != null && rtp.missions.isEmpty) {
                    return PremiumWidgets.premiumCard(
                      child: PremiumWidgets.emptyState(
                        title: 'Error loading missions',
                        message: rtp.errorMessage!,
                        icon: Icons.error_outline,
                        buttonText: 'Retry',
                        onAction: () => rtp.loadMissions(),
                      ),
                    );
                  }
                  if (rtp.missions.isEmpty) {
                    return PremiumWidgets.emptyState(
                      title: 'No missions assigned',
                      message: 'Missions assigned to you will appear here',
                      icon: Icons.assignment_outlined,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Your Missions',
                              style: PremiumAppTheme.headlineSmall,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.assignedIncidents,
                              );
                            },
                            icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                            label: const Text('Assigned'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.organizationMembers,
                              );
                            },
                            icon: const Icon(Icons.groups_2_rounded, size: 18),
                            label: const Text('Members'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...rtp.missions.map((mission) {
                        return _MissionCard(
                          mission: mission,
                          onUpdateStatus: (status) async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final result = await rtp.updateMissionStatus(
                              mission.missionId,
                              status,
                            );
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] as String? ?? 'Done',
                                ),
                                backgroundColor: result['success'] == true
                                    ? PremiumAppTheme.success
                                    : PremiumAppTheme.emergency,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          onTapIncident: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.missionDetails,
                              arguments: {'mission': mission},
                            );
                          },
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.onUpdateStatus,
    required this.onTapIncident,
  });
  final MissionModel mission;
  final void Function(String status) onUpdateStatus;
  final VoidCallback onTapIncident;

  @override
  Widget build(BuildContext context) {
    final incident = mission.incident;
    final title = incident?.title ?? 'Incident #${mission.incidentId}';
    final status = mission.missionStatus;
    final statusColor = status == 'completed'
        ? PremiumAppTheme.success
        : status == 'in_progress'
        ? Colors.orange
        : PremiumAppTheme.info;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PremiumWidgets.premiumCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: PremiumAppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: PremiumAppTheme.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (incident?.description != null &&
                incident!.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                incident.description,
                style: PremiumAppTheme.bodySmall.copyWith(
                  color: PremiumAppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Assigned ${_formatDate(mission.assignedAt)}',
              style: PremiumAppTheme.labelSmall.copyWith(
                color: PremiumAppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (status != 'completed')
                  OutlinedButton(
                    onPressed: () => onUpdateStatus('in_progress'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                    child: const Text('In progress'),
                  ),
                if (status != 'completed')
                  OutlinedButton(
                    onPressed: () => onUpdateStatus('completed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PremiumAppTheme.success,
                      side: const BorderSide(color: PremiumAppTheme.success),
                    ),
                    child: const Text('Complete'),
                  ),
                TextButton(
                  onPressed: onTapIncident,
                  child: const Text('View details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day(s) ago';
  }
}

class RescueTeamIncidentsTab extends StatelessWidget {
  const RescueTeamIncidentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<IncidentProvider, RescueTeamProvider>(
      builder: (context, provider, rescueTeamProvider, _) {
        final assignedIncidentIds = rescueTeamProvider.missions
            .map((m) => m.incidentId)
            .toSet();

        return Scaffold(
          appBar: PremiumAppBar(
            title: 'Incidents',
            actions: [
              const NotificationBadge(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadIncidents(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.loadIncidents(),
            child: provider.isLoading
                ? PremiumWidgets.loadingIndicator(
                    message: 'Loading incidents...',
                  )
                : provider.errorMessage != null
                ? PremiumWidgets.emptyState(
                    title: 'Error loading incidents',
                    message: provider.errorMessage!,
                    icon: Icons.error_outline,
                    buttonText: 'Retry',
                    onAction: () => provider.loadIncidents(),
                  )
                : (provider.incidents.isEmpty && provider.pendingIncidents.isEmpty)
                ? PremiumWidgets.emptyState(
                    title: 'No incidents reported',
                    message: 'Incidents will appear here',
                    icon: Icons.warning_amber_outlined,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (provider.pendingIncidents.isNotEmpty) ...[
                        Text(
                          'Pending Sync (${provider.pendingIncidents.length})',
                          style: PremiumAppTheme.labelMedium.copyWith(
                            color: PremiumAppTheme.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...provider.pendingIncidents.map((item) {
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
                      ...provider.incidents.map((incident) {
                        final incidentMissionId = incident.missionIds != null &&
                                incident.missionIds!.isNotEmpty
                            ? incident.missionIds!.first
                            : null;
                        final canRequestJoin = incidentMissionId != null &&
                            !assignedIncidentIds.contains(incident.incidentId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: PremiumWidgets.incidentCard(
                            title: incident.title,
                            description: incident.description,
                            location:
                                incident.location?.address ?? 'Unknown location',
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
                            actions: canRequestJoin
                                ? [
                                    PremiumWidgets.premiumButton(
                                      text: 'Request Join',
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final result = await rescueTeamProvider
                                            .requestMissionAssignment(
                                              incidentMissionId,
                                            );
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['message']?.toString() ??
                                                  'Done',
                                            ),
                                            backgroundColor:
                                                result['success'] == true
                                                ? PremiumAppTheme.success
                                                : PremiumAppTheme.emergency,
                                          ),
                                        );
                                      },
                                      height: 34,
                                      backgroundColor: Colors.blue.shade700,
                                      icon: Icons.send_rounded,
                                    ),
                                  ]
                                : null,
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

