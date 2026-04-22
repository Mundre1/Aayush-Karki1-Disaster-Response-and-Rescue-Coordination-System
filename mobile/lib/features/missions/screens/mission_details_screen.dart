import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import '../models/mission_model.dart';
import '../../rescue_team/rescue_team_provider.dart';
import '../../auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/routes/app_routes.dart';

class MissionDetailsScreen extends StatefulWidget {
  final MissionModel mission;

  const MissionDetailsScreen({super.key, required this.mission});

  @override
  State<MissionDetailsScreen> createState() => _MissionDetailsScreenState();
}

class _MissionDetailsScreenState extends State<MissionDetailsScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String status) async {
    final payload = await _collectMissionUpdatePayload(status);
    if (!mounted || payload == null) return;

    setState(() => _isUpdating = true);
    final provider = Provider.of<RescueTeamProvider>(context, listen: false);
    final result = await provider.updateMissionStatus(
      widget.mission.missionId,
      status,
      note: payload['note'] as String?,
      imageBytes: payload['imageBytes'] as Uint8List?,
      imageFileName: payload['imageFileName'] as String?,
      imageUrl: payload['imageUrl'] as String?,
      imagePath: payload['imagePath'] as String?,
    );
    if (mounted) {
      setState(() => _isUpdating = false);
      final message = (result['message'] ?? 'Status updated').toString();
      final normalized = message.toLowerCase();
      final prettyMessage = normalized.contains('insufficient permissions')
          ? 'Only responder/admin accounts can update mission status.'
          : message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prettyMessage),
          backgroundColor: result['success'] ? PremiumAppTheme.success : PremiumAppTheme.emergency,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (result['success']) {
        Navigator.pop(context);
      }
    }
  }

  Future<Map<String, dynamic>?> _collectMissionUpdatePayload(String status) async {
    String noteText = '';
    String imageUrlText = '';
    String? imagePath;
    String? imageFileName;

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> pickPhoto() async {
              final picker = ImagePicker();
              final photo = await picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 80,
              );
              if (photo == null) return;
              
              setLocalState(() {
                imagePath = photo.path;
                imageFileName = photo.name;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Update mission to ${status.toUpperCase()}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      maxLines: 3,
                      onChanged: (value) => noteText = value,
                      decoration: InputDecoration(
                        labelText: 'Situation note (optional)',
                        hintText: 'Brief update about ground situation',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) => imageUrlText = value,
                      decoration: InputDecoration(
                        labelText: 'Image URL (optional)',
                        hintText: 'https://example.com/update.jpg',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (imagePath != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(imagePath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            onPressed: () {
                              setLocalState(() {
                                imagePath = null;
                                imageFileName = null;
                              });
                            },
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: pickPhoto,
                        icon: Icon(imagePath == null ? Icons.camera_alt_rounded : Icons.refresh_rounded),
                        label: Text(
                          imagePath == null ? 'Take Update Photo' : 'Retake Photo',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Close keyboard before popping
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context, {
                      'note': noteText.trim().isEmpty ? null : noteText.trim(),
                      'imageUrl': imageUrlText.trim().isEmpty ? null : imageUrlText.trim(),
                      'imagePath': imagePath,
                      'imageFileName': imageFileName,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumAppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    return payload;
  }

  Future<void> _makeCall(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openDirections() async {
    final location = widget.mission.incident?.location;
    if (location == null) return;

    final lat = location.latitude;
    final lng = location.longitude;

    final googleMapsAppUri = Uri.parse('google.navigation:q=$lat,$lng');
    final googleMapsWebUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsAppUri)) {
      await launchUrl(googleMapsAppUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(googleMapsWebUri)) {
      await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Google Maps for directions.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.mission.incident;
    final status = widget.mission.missionStatus;
    final authUser = context.watch<AuthProvider>().user;
    final roleName = authUser?.roleName?.toLowerCase() ?? '';
    final canUpdateMission = roleName == 'responder' || roleName == 'rescue_team' || roleName == 'admin';
    
    Color statusColor = PremiumAppTheme.info;
    if (status == 'completed') statusColor = PremiumAppTheme.success;
    if (status == 'in_progress') statusColor = Colors.orange;

    return Scaffold(
      backgroundColor: PremiumAppTheme.background,
      appBar: PremiumAppBar(
        title: 'Mission Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            PremiumWidgets.premiumCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status == 'completed' ? Icons.check_circle_outline : Icons.assignment_late_outlined,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mission ${status.replaceAll('_', ' ').toUpperCase()}',
                          style: PremiumAppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          'Assigned on ${_formatDate(widget.mission.assignedAt)}',
                          style: PremiumAppTheme.labelSmall.copyWith(
                            color: PremiumAppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Incident Info Section
            _buildSectionHeader('Incident Information', Icons.warning_amber_rounded),
            const SizedBox(height: 12),
            PremiumWidgets.premiumCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident?.title ?? 'Untitled Incident',
                    style: PremiumAppTheme.headlineSmall.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  _buildSeverityBadge(incident?.severity ?? 'medium'),
                  const SizedBox(height: 16),
                  Text(
                    incident?.description ?? 'No description provided.',
                    style: PremiumAppTheme.bodyMedium.copyWith(
                      color: PremiumAppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.incidentDetails,
                    arguments: {'incidentId': widget.mission.incidentId},
                  );
                },
                icon: const Icon(Icons.history_toggle_off_rounded),
                label: const Text('Open Incident History & Discussion'),
              ),
            ),
            const SizedBox(height: 24),

            // Location Section
            _buildSectionHeader('Location', Icons.location_on_rounded),
            const SizedBox(height: 12),
            PremiumWidgets.premiumCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PremiumAppTheme.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.map_rounded, color: PremiumAppTheme.info),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          incident?.location?.address ?? 'Location details not available',
                          style: PremiumAppTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  if (incident?.location != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openDirections,
                        icon: const Icon(Icons.directions_rounded),
                        label: const Text('Get Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumAppTheme.info,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reporter Section
            if (incident?.reporterName != null) ...[
              _buildSectionHeader('Reporter Contact', Icons.person_rounded),
              const SizedBox(height: 12),
              PremiumWidgets.premiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Text(incident!.reporterName![0].toUpperCase()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.reporterName!,
                            style: PremiumAppTheme.titleMedium,
                          ),
                          if (incident.reporterPhone != null)
                            Text(
                              incident.reporterPhone!,
                              style: PremiumAppTheme.bodySmall.copyWith(
                                color: PremiumAppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (incident.reporterPhone != null)
                      IconButton(
                        icon: const Icon(Icons.call_rounded, color: PremiumAppTheme.success),
                        onPressed: () => _makeCall(incident.reporterPhone!),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Actions Section
            if (status != 'completed' && canUpdateMission) ...[
              _buildSectionHeader('Actions', Icons.play_arrow_rounded),
              const SizedBox(height: 12),
              if (_isUpdating)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    if (status == 'assigned')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus('in_progress'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('START MISSION'),
                        ),
                      ),
                    if (status == 'assigned') const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus('completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumAppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('COMPLETE MISSION'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
            if (status != 'completed' && !canUpdateMission) ...[
              _buildSectionHeader('Actions', Icons.play_arrow_rounded),
              const SizedBox(height: 12),
              PremiumWidgets.premiumCard(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Mission updates are available only for responder/admin accounts.',
                  style: PremiumAppTheme.bodySmall.copyWith(
                    color: PremiumAppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: PremiumAppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: PremiumAppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color = PremiumAppTheme.success;
    if (severity == 'high' || severity == 'critical') color = PremiumAppTheme.emergency;
    if (severity == 'medium') color = PremiumAppTheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: PremiumAppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} at ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}
