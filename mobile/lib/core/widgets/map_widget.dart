import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../../features/incidents/models/incident_model.dart';

class MapWidget extends StatelessWidget {
  final LatLng? userLocation;
  final List<IncidentModel> incidents;
  final List<Map<String, dynamic>> teamLocations;
  final double? initialZoom;
  final LatLng? initialCenter;
  final Function(IncidentModel)? onIncidentTap;
  final bool showUserLocation;
  final bool showIncidents;
  final MapController? mapController;

  const MapWidget({
    super.key,
    this.userLocation,
    this.incidents = const [],
    this.teamLocations = const [],
    this.initialZoom,
    this.initialCenter,
    this.onIncidentTap,
    this.showUserLocation = true,
    this.showIncidents = true,
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    // Determine initial center
    LatLng center =
        initialCenter ??
        (userLocation != null
            ? userLocation!
            : const LatLng(
                AppConfig.defaultLatitude,
                AppConfig.defaultLongitude,
              ));

    // Determine initial zoom
    double zoom = initialZoom ?? AppConfig.defaultZoom;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: AppConfig.minZoom,
        maxZoom: AppConfig.maxZoom,
        onTap: (tapPosition, point) {
          // Handle map tap if needed
        },
      ),
      children: [
        // Tile layer (OpenStreetMap)
        TileLayer(
          urlTemplate: AppConfig.mapTileUrl,
          userAgentPackageName: 'com.disaster.response',
          maxZoom: 19,
        ),

        // User location marker
        if (showUserLocation && userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: PremiumAppTheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: PremiumAppTheme.primary,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: PremiumAppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

        // Team locations markers
        if (teamLocations.isNotEmpty)
          MarkerLayer(
            markers: teamLocations
                .map((location) {
                  final lat = location['latitude'];
                  final lng = location['longitude'];
                  if (lat == null || lng == null) return null;

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.health_and_safety,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                })
                .whereType<Marker>()
                .toList(),
          ),

        // Incident markers
        if (showIncidents)
          MarkerLayer(
            markers: incidents
                .map((incident) {
                  if (incident.location == null) return null;

                  final color = _getSeverityColor(incident.severity);
                  return Marker(
                    point: LatLng(
                      incident.location!.latitude,
                      incident.location!.longitude,
                    ),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        if (onIncidentTap != null) {
                          onIncidentTap!(incident);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: color,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .whereType<Marker>()
                .toList(),
          ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return PremiumAppTheme.success;
      case 'medium':
        return PremiumAppTheme.warning;
      case 'high':
        return PremiumAppTheme.emergencyLight;
      case 'critical':
        return PremiumAppTheme.emergencyDark;
      default:
        return PremiumAppTheme.neutral;
    }
  }
}

