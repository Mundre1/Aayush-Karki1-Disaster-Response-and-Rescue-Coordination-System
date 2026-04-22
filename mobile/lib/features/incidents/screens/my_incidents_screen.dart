import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../incident_provider.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../missions/models/mission_model.dart';

class MyIncidentsScreen extends StatefulWidget {
  const MyIncidentsScreen({super.key});

  @override
  State<MyIncidentsScreen> createState() => _MyIncidentsScreenState();
}

class _MyIncidentsScreenState extends State<MyIncidentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<IncidentProvider>(context, listen: false).loadMyIncidents();
    });
  }

  Future<void> _showDeleteDialog(int incidentId, String title) async {
    if (!mounted) return;

    // Store references before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final incidentProvider = Provider.of<IncidentProvider>(
      context,
      listen: false,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PremiumAppTheme.background,
        title: Text(
          'Delete Incident',
          style: PremiumAppTheme.titleLarge.copyWith(
            color: PremiumAppTheme.emergency,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$title"? This action cannot be undone.',
          style: PremiumAppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: PremiumAppTheme.bodyMedium.copyWith(
                color: PremiumAppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumAppTheme.emergency,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      final success = await incidentProvider.deleteIncident(incidentId);

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Incident deleted successfully'
                  : incidentProvider.errorMessage ??
                        'Failed to delete incident',
              style: PremiumAppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: success
                ? PremiumAppTheme.success
                : PremiumAppTheme.emergency,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumAppTheme.background,
      appBar: PremiumAppBar(
        title: 'My Incidents',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<IncidentProvider>(
                context,
                listen: false,
              ).loadMyIncidents();
            },
          ),
        ],
      ),
      body: Consumer<IncidentProvider>(
        builder: (context, incidentProvider, child) {
          if (incidentProvider.isLoadingMyIncidents) {
            return PremiumWidgets.loadingIndicator(
              message: 'Loading your incidents...',
            );
          }

          if (incidentProvider.errorMessage != null &&
              incidentProvider.myIncidents.isEmpty) {
            return PremiumWidgets.emptyState(
              title: 'Error loading incidents',
              message: incidentProvider.errorMessage!,
              icon: Icons.error_outline,
              buttonText: 'Retry',
              onAction: () => incidentProvider.loadMyIncidents(),
            );
          }

          final incidents = incidentProvider.myIncidents;

          if (incidents.isEmpty) {
            return PremiumWidgets.emptyState(
              title: 'No incidents reported',
              message: 'You haven\'t reported any incidents yet',
              icon: Icons.add_circle_outline,
              buttonText: 'Report Incident',
              onAction: () =>
                  Navigator.pushNamed(context, AppRoutes.reportIncident),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await incidentProvider.loadMyIncidents();
            },
            color: PremiumAppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PremiumWidgets.premiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    incident.title,
                                    style: PremiumAppTheme.titleMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    incident.description,
                                    style: PremiumAppTheme.bodyMedium.copyWith(
                                      color: PremiumAppTheme.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: PremiumAppTheme.textSecondary,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.editIncident,
                                    arguments: {
                                      'incidentId': incident.incidentId,
                                    },
                                  );
                                } else if (value == 'delete') {
                                  _showDeleteDialog(
                                    incident.incidentId,
                                    incident.title,
                                  );
                                } else if (value == 'view') {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.incidentDetails,
                                    arguments: {
                                      'incidentId': incident.incidentId,
                                    },
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        size: 20,
                                        color: PremiumAppTheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('View Details'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: PremiumAppTheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: PremiumAppTheme.emergency,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: PremiumAppTheme.emergency,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(
                                  incident.severity,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getSeverityColor(incident.severity),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                incident.severity.toUpperCase(),
                                style: PremiumAppTheme.labelSmall.copyWith(
                                  color: _getSeverityColor(incident.severity),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  incident.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(incident.status),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                incident.status.toUpperCase(),
                                style: PremiumAppTheme.labelSmall.copyWith(
                                  color: _getStatusColor(incident.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (incident.location?.address != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: PremiumAppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  incident.location!.address!,
                                  style: PremiumAppTheme.bodySmall.copyWith(
                                    color: PremiumAppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Reported ${_formatDate(incident.reportedAt)}',
                          style: PremiumAppTheme.bodySmall.copyWith(
                            color: PremiumAppTheme.textDisabled,
                          ),
                        ),
                        if (incident.missions != null && incident.missions!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 16,
                                color: Colors.indigo.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Mission assigned to ${incident.missions!.first.rescueTeamName ?? 'rescue team'}',
                                  style: PremiumAppTheme.bodySmall.copyWith(
                                    color: Colors.indigo.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  final mission = incident.missions!.first;
                                  final missionModel = MissionModel(
                                    missionId: mission.missionId,
                                    incidentId: incident.incidentId,
                                    rescueTeamId: mission.rescueTeamId,
                                    missionStatus: mission.missionStatus ?? 'assigned',
                                    assignedAt: mission.assignedAt ?? incident.reportedAt,
                                    completedAt: mission.completedAt,
                                    incident: MissionIncidentInfo(
                                      incidentId: incident.incidentId,
                                      title: incident.title,
                                      description: incident.description,
                                      severity: incident.severity,
                                      status: incident.status,
                                      location: incident.location,
                                      reporterName: incident.user?.name,
                                      reporterPhone: incident.user?.phone,
                                    ),
                                    rescueTeam: mission.rescueTeamName != null
                                        ? RescueTeamInfo(
                                            teamId: mission.rescueTeamId ?? 0,
                                            teamName: mission.rescueTeamName!,
                                          )
                                        : null,
                                  );
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.missionDetails,
                                    arguments: {'mission': missionModel},
                                  );
                                },
                                child: const Text('View Mission'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return PremiumAppTheme.emergency;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return PremiumAppTheme.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return PremiumAppTheme.textSecondary;
      default:
        return PremiumAppTheme.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

