import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../../incidents/incident_provider.dart';
import '../../auth/auth_provider.dart';
import '../../rescue_team/rescue_team_provider.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/map_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/map_service.dart';
import '../../../core/config/app_config.dart';

/// Reusable map tab for Citizen, Volunteer, and Rescue Team dashboards.
/// Shows incidents on map, user location, and handles location permission.
class MapTabContent extends StatefulWidget {
  const MapTabContent({
    super.key,
    this.title = 'Map',
    this.fabColor,
    this.heroTag = 'map_fab',
  });

  final String title;
  final Color? fabColor;
  final String heroTag;

  @override
  State<MapTabContent> createState() => _MapTabContentState();
}

class _MapTabContentState extends State<MapTabContent> {
  final MapService _mapService = MapService();
  final MapController _mapController = MapController();
  final SocketService _socketService = SocketService();

  Position? _userPosition;
  bool _isLoadingLocation = false;
  String? _locationError;

  // Rescue team specific state
  bool _isDuty = false;
  Timer? _dutyTimer;
  final Map<int, Map<String, dynamic>> _teamLocations = {};

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<IncidentProvider>(context, listen: false).loadIncidents();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.roleName == 'responder' ||
          authProvider.user?.roleName == 'rescue_team') {
         _socketService.onRescueTeamLocation((data) {
           if (mounted) {
             setState(() {
                final userId = data['userId'];
                if (userId != null) {
                  _teamLocations[userId] = Map<String, dynamic>.from(data);
                }
             });
           }
         });
      }
    });
  }

  void _toggleDuty() {
    setState(() {
      _isDuty = !_isDuty;
    });

    if (_isDuty) {
       _sendLocationUpdate(); // Send immediately
       _dutyTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
          _sendLocationUpdate();
       });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: const Text('You are now ON DUTY. Sharing location...'),
           backgroundColor: PremiumAppTheme.success,
           behavior: SnackBarBehavior.floating,
         ),
       );
    } else {
       _dutyTimer?.cancel();
       _dutyTimer = null;
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('You are now OFF DUTY.'),
           behavior: SnackBarBehavior.floating,
         ),
       );
    }
  }

  Future<void> _sendLocationUpdate() async {
    if (!mounted) return;
    try {
      final position = await _mapService.getCurrentLocation(requestPermission: false);
      if (!mounted) return;
      if (position != null) {
        await Provider.of<RescueTeamProvider>(context, listen: false)
            .updateLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Error sending location update: $e');
    }
  }

  Future<void> _loadUserLocation({bool requestPermission = true}) async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });
    try {
      final status = await _mapService.getLocationStatus();
      if (!status['serviceEnabled']) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationError =
                'Location services are disabled. Please enable them in settings.';
          });
        }
        return;
      }
      if (status['isDeniedForever']) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationError =
                'Location permission denied. Please enable in app settings.';
          });
        }
        return;
      }
      final position = await _mapService.getCurrentLocation(
        requestPermission: requestPermission,
      );
      if (position != null && mounted) {
        setState(() {
          _userPosition = position;
          _isLoadingLocation = false;
          _locationError = null;
        });
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          AppConfig.defaultZoom,
        );
      } else if (mounted) {
        final perm = await _mapService.getLocationStatus();
        setState(() {
          _isLoadingLocation = false;
          _locationError = perm['isDenied'] && requestPermission
              ? 'Location permission denied. Tap to request permission.'
              : 'Location not available';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Error getting location: $e';
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await _mapService.getLocationStatus();
    if (status['isDeniedForever']) {
      final opened = await _mapService.openAppSettings();
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enable location permission in app settings',
              style: PremiumAppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: PremiumAppTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else {
      await _loadUserLocation(requestPermission: true);
    }
  }

  void _centerOnUser() {
    if (_userPosition != null) {
      _mapController.move(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        AppConfig.defaultZoom,
      );
    } else {
      _loadUserLocation(requestPermission: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fabColor = widget.fabColor ?? PremiumAppTheme.primary;
    final roleName = Provider.of<AuthProvider>(context).user?.roleName;
    final isRescueTeam = roleName == 'responder' || roleName == 'rescue_team';

    return Scaffold(
      backgroundColor: PremiumAppTheme.background,
      appBar: PremiumAppBar(
        title: widget.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<IncidentProvider>(
                context,
                listen: false,
              ).loadIncidents();
              _loadUserLocation();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<IncidentProvider>(
        builder: (context, incidentProvider, _) {
          LatLng? userLoc;
          if (_userPosition != null) {
            userLoc = LatLng(_userPosition!.latitude, _userPosition!.longitude);
          }
          return Stack(
            children: [
              MapWidget(
                mapController: _mapController,
                userLocation: userLoc,
                incidents: incidentProvider.incidents,
                teamLocations: _teamLocations.values.toList(),
                onIncidentTap: (incident) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.incidentDetails,
                    arguments: {'incidentId': incident.incidentId},
                  );
                },
                showUserLocation: true,
                showIncidents: true,
              ),
              if (_isLoadingLocation || incidentProvider.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: PremiumWidgets.loadingIndicator(
                      message: _isLoadingLocation
                          ? 'Getting your location...'
                          : 'Loading incidents...',
                    ),
                  ),
                ),
              if (_locationError != null && !_isLoadingLocation)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PremiumAppTheme.warning.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_off,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationError!,
                                style: PremiumAppTheme.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _locationError = null);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _requestLocationPermission,
                            icon: const Icon(Icons.location_on, size: 18),
                            label: const Text('Request Permission'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: PremiumAppTheme.warning,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 24,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isRescueTeam) ...[
                      FloatingActionButton.extended(
                        heroTag: 'duty_fab',
                        onPressed: _toggleDuty,
                        backgroundColor: _isDuty ? PremiumAppTheme.success : Colors.grey,
                        icon: Icon(
                          _isDuty ? Icons.shield : Icons.shield_outlined,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isDuty ? 'ON DUTY' : 'GO ON DUTY',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FloatingActionButton(
                      heroTag: widget.heroTag,
                      onPressed: _centerOnUser,
                      backgroundColor: fabColor,
                      tooltip: 'My Location',
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (incidentProvider.incidents.isNotEmpty)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: PremiumAppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: fabColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${incidentProvider.incidents.length} incidents',
                          style: PremiumAppTheme.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _dutyTimer?.cancel();
    _socketService.offRescueTeamLocation();
    _mapService.dispose();
    super.dispose();
  }
}

