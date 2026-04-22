import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../incident_provider.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';

class IncidentListScreen extends StatefulWidget {
  /// When true, no [AppBar] is shown (e.g. inside [DashboardScreen] which owns the bar).
  final bool embeddedInDashboard;

  const IncidentListScreen({super.key, this.embeddedInDashboard = false});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<IncidentProvider>(context, listen: false).loadIncidents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumAppTheme.background,
      appBar: widget.embeddedInDashboard
          ? null
          : PremiumAppBar(
              title: 'Incidents',
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    Provider.of<IncidentProvider>(
                      context,
                      listen: false,
                    ).loadIncidents();
                  },
                ),
              ],
            ),
      body: Consumer<IncidentProvider>(
        builder: (context, incidentProvider, child) {
          if (incidentProvider.isLoading) {
            return PremiumWidgets.loadingIndicator(
              message: 'Loading incidents...',
            );
          }

          if (incidentProvider.errorMessage != null) {
            return PremiumWidgets.emptyState(
              title: 'Error loading incidents',
              message: incidentProvider.errorMessage!,
              icon: Icons.error_outline,
              buttonText: 'Retry',
              onAction: () => incidentProvider.loadIncidents(),
            );
          }

          final incidents = incidentProvider.incidents;

          if (incidents.isEmpty) {
            return PremiumWidgets.emptyState(
              title: 'No incidents reported',
              message: 'Be the first to report an incident in your area',
              icon: Icons.warning_amber_outlined,
              buttonText: 'Report Incident',
              onAction: () =>
                  Navigator.pushNamed(context, AppRoutes.reportIncident),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await incidentProvider.loadIncidents();
            },
            color: PremiumAppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'incident_list_fab',
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.reportIncident);
        },
        backgroundColor: PremiumAppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
