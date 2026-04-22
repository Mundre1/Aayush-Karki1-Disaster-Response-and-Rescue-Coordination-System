import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../rescue_team/rescue_team_provider.dart';

class AssignedIncidentsScreen extends StatefulWidget {
  const AssignedIncidentsScreen({super.key});

  @override
  State<AssignedIncidentsScreen> createState() => _AssignedIncidentsScreenState();
}

class _AssignedIncidentsScreenState extends State<AssignedIncidentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RescueTeamProvider>().loadMissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RescueTeamProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: const PremiumAppBar(title: 'Assigned Incidents'),
          body: RefreshIndicator(
            onRefresh: provider.loadMissions,
            child: provider.isLoading
                ? PremiumWidgets.loadingIndicator(message: 'Loading assigned incidents...')
                : provider.missions.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          PremiumWidgets.emptyState(
                            title: 'No assigned incidents',
                            message: 'Incidents assigned to your organization appear here.',
                            icon: Icons.assignment_outlined,
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.missions.length,
                        itemBuilder: (context, index) {
                          final mission = provider.missions[index];
                          final incident = mission.incident;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PremiumWidgets.incidentCard(
                              title: incident?.title ?? 'Incident #${mission.incidentId}',
                              description: incident?.description ?? 'Assigned mission',
                              location: incident?.location?.address ?? 'Unknown location',
                              status: mission.missionStatus,
                              severity: incident?.severity ?? 'medium',
                              reportedAt: mission.assignedAt,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.missionDetails,
                                  arguments: {'mission': mission},
                                );
                              },
                              actions: [
                                Text(
                                  'Assigned',
                                  style: PremiumAppTheme.bodySmall.copyWith(
                                    color: PremiumAppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        );
      },
    );
  }
}
