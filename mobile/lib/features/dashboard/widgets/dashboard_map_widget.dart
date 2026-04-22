import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/map_widget.dart';
import '../../incidents/incident_provider.dart';

class DashboardMapWidget extends StatelessWidget {
  const DashboardMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentProvider>(
      builder: (context, incidentProvider, child) {
        if (incidentProvider.isLoading && incidentProvider.incidents.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return MapWidget(
          incidents: incidentProvider.incidents,
          showUserLocation: true,
          onIncidentTap: (incident) {
            Navigator.pushNamed(
              context,
              '/incident-details',
              arguments: {'incidentId': incident.incidentId},
            );
          },
        );
      },
    );
  }
}
