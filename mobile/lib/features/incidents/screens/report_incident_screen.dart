import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../incident_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/map_widget.dart';
import '../../../core/services/map_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _selectedSeverity = 'medium';
  Uint8List? _imageBytes;
  String? _imageFileName;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isResolvingAddress = false;
  String? _locationError;
  final MapService _mapService = MapService();

  final List<String> _severityOptions = ['low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation({bool requestPermission = true}) async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check location status first
      final status = await _mapService.getLocationStatus();

      if (!status['serviceEnabled']) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationError =
                'Location services are disabled. Please enable them in device settings.';
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

      // Try to get location (will request permission if needed)
      final position = await _mapService.getCurrentLocation(
        requestPermission: requestPermission,
      );

      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
          _locationError = null;
        });
        await _autoFillAddressFromLocation(position);
      } else {
        if (mounted) {
          final permissionStatus = await _mapService.getLocationStatus();
          if (permissionStatus['isDenied'] && requestPermission) {
            setState(() {
              _isLoadingLocation = false;
              _locationError =
                  'Location permission denied. Tap "Request Permission" to enable.';
            });
          } else {
            setState(() {
              _isLoadingLocation = false;
              _locationError = 'Unable to get location. Please try again.';
            });
          }
        }
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

  Future<void> _autoFillAddressFromLocation(Position position) async {
    if (!mounted) return;
    setState(() => _isResolvingAddress = true);
    final geocode = await _mapService.reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted) return;
    setState(() {
      if ((geocode['address'] ?? '').trim().isNotEmpty) {
        _addressController.text = geocode['address']!;
      }
      if ((geocode['district'] ?? '').trim().isNotEmpty) {
        _districtController.text = geocode['district']!;
      }
      _isResolvingAddress = false;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await _mapService.getLocationStatus();

    if (status['isDeniedForever']) {
      // Open app settings
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
      // Request permission and reload location
      await _getCurrentLocation(requestPermission: true);
    }
  }

  Future<void> _pickImage() async {
    // Unfocus any active text field before opening the camera to avoid layout issues
    FocusScope.of(context).unfocus();

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920, // Limit size to avoid OOM
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFileName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: PremiumAppTheme.emergency,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please wait for location to be fetched',
              style: PremiumAppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: PremiumAppTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      final incidentProvider = Provider.of<IncidentProvider>(
        context,
        listen: false,
      );

      final success = await incidentProvider.reportIncident(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        severity: _selectedSeverity,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        district: _districtController.text.trim().isEmpty
            ? null
            : _districtController.text.trim(),
        imageBytes: _imageBytes,
        imageFileName: _imageFileName,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report received. It is pending review — coordinators will verify details and may assign rescue teams. '
              'You can track status under My Incidents.',
              style: PremiumAppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: PremiumAppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              incidentProvider.errorMessage ?? 'Failed to report incident',
              style: PremiumAppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: PremiumAppTheme.emergency,
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
      appBar: const PremiumAppBar(title: 'Report Incident'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedSeverity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: _severityOptions.map((String severity) {
                  return DropdownMenuItem<String>(
                    value: severity,
                    child: Text(severity.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSeverity = value!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Auto-filled from map)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'District (Auto-filled from map)',
                ),
              ),
              if (_isResolvingAddress)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Auto-filling address from selected location...',
                        style: PremiumAppTheme.bodySmall.copyWith(
                          color: PremiumAppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (_isLoadingLocation)
                PremiumWidgets.premiumCard(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: PremiumAppTheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Getting your location...',
                        style: PremiumAppTheme.bodyMedium.copyWith(
                          color: PremiumAppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_currentPosition != null)
                PremiumWidgets.premiumCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: PremiumAppTheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location Captured',
                                style: PremiumAppTheme.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Refresh'),
                              style: TextButton.styleFrom(
                                foregroundColor: PremiumAppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 250,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          child: MapWidget(
                            userLocation: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            incidents: const [],
                            initialCenter: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            initialZoom: 15.0,
                            showUserLocation: true,
                            showIncidents: false,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coordinates:',
                              style: PremiumAppTheme.bodySmall.copyWith(
                                color: PremiumAppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                              style: PremiumAppTheme.bodyMedium.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                              style: PremiumAppTheme.bodyMedium.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                PremiumWidgets.premiumCard(
                  child: Column(
                    children: [
                      Icon(
                        _locationError != null
                            ? Icons.location_off
                            : Icons.location_searching,
                        size: 48,
                        color: _locationError != null
                            ? PremiumAppTheme.emergency
                            : PremiumAppTheme.textDisabled,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _locationError != null
                            ? 'Location Permission Required'
                            : 'Location not available',
                        style: PremiumAppTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _locationError ??
                            'Please enable location services to report an incident',
                        style: PremiumAppTheme.bodySmall.copyWith(
                          color: PremiumAppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_locationError != null)
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _requestLocationPermission,
                              icon: const Icon(Icons.location_on),
                              label: const Text('Request Permission'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PremiumAppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: PremiumAppTheme.primary,
                              ),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () =>
                              _getCurrentLocation(requestPermission: true),
                          icon: const Icon(Icons.location_on),
                          label: const Text('Get Current Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PremiumAppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  hintText: 'https://example.com/photo.jpg',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 16),
              if (_imageBytes != null)
                PremiumWidgets.premiumCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _imageBytes!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumAppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tip: You can use camera upload or an image URL.',
                      style: PremiumAppTheme.bodySmall.copyWith(
                        color: PremiumAppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Consumer<IncidentProvider>(
                builder: (context, incidentProvider, _) {
                  return PremiumWidgets.premiumButton(
                    text: 'Report Incident',
                    onPressed: _handleSubmit,
                    isLoading: incidentProvider.isLoading,
                    icon: Icons.send,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
