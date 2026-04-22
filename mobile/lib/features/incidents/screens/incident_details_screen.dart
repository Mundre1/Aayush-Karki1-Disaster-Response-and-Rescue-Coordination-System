import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../incident_provider.dart';
import '../models/incident_model.dart';
import '../../comments/comment_provider.dart';
import '../../comments/models/comment_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';

import '../../../core/widgets/map_widget.dart';
import '../../../core/config/app_config.dart';
import '../../missions/models/mission_model.dart';
import '../../../core/routes/app_routes.dart';

class IncidentDetailsScreen extends StatefulWidget {
  final int? incidentId;

  const IncidentDetailsScreen({super.key, this.incidentId});

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen>
    with SingleTickerProviderStateMixin {
  IncidentModel? _incident;
  late TabController _tabController;

  /// Cached so [dispose] can call [CommentProvider.stopListening] without using [context]
  /// (the element is already deactivated there).
  CommentProvider? _commentProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadIncident();
    if (widget.incidentId != null) {
       // Load comments
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (!mounted) return;
         final commentProvider = Provider.of<CommentProvider>(context, listen: false);
         commentProvider.loadComments(widget.incidentId!);
         commentProvider.listenToComments(widget.incidentId!);
       });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _commentProvider ??= Provider.of<CommentProvider>(context, listen: false);
  }

  @override
  void dispose() {
    if (widget.incidentId != null) {
       _commentProvider?.stopListening();
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIncident() async {
    if (widget.incidentId != null) {
      final incidentProvider = Provider.of<IncidentProvider>(
        context,
        listen: false,
      );
      final incident = await incidentProvider.getIncidentById(
        widget.incidentId!,
      );
      if (mounted) {
        setState(() {
          _incident = incident;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Incident Details',
          style: PremiumAppTheme.headlineSmall,
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: PremiumAppTheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: PremiumAppTheme.primary,
              unselectedLabelColor: PremiumAppTheme.textSecondary,
              labelStyle: PremiumAppTheme.labelLarge.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: PremiumAppTheme.labelLarge,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'History'),
                Tab(text: 'Discussion'),
              ],
            ),
          ),
        ),
      ),
      body: _incident == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  Text(
                    'Loading incident details...',
                    style: PremiumAppTheme.bodyMedium.copyWith(
                      color: PremiumAppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildHistoryTab(),
                _buildCommentsTab(),
              ],
            ),
    );
  }

  Widget _buildDetailsTab() {
    final incidentImageUrl = _resolveIncidentImageUrl(_incident!.imageUrl);
    final assignedTeamName = _assignedTeamName(_incident!);
    final assignedByName = _assignedByName(_incident!);

    return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Severity Badges
                  Row(
                    children: [
                      _buildStatusBadge(_incident!.status),
                      const SizedBox(width: 8),
                      _buildSeverityBadge(_incident!.severity),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PremiumAppTheme.getStatusColor(_incident!.status).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PremiumAppTheme.getStatusColor(_incident!.status).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: PremiumAppTheme.getStatusColor(_incident!.status),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusGuidance(_incident!.status),
                            style: PremiumAppTheme.bodyMedium.copyWith(
                              color: PremiumAppTheme.textPrimary.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _incident!.title,
                    style: PremiumAppTheme.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  PremiumWidgets.premiumCard(
                    backgroundColor: Colors.white,
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: PremiumAppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.description_outlined, size: 18, color: PremiumAppTheme.primary),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Description',
                              style: PremiumAppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _incident!.description,
                          style: PremiumAppTheme.bodyLarge.copyWith(
                            color: PremiumAppTheme.textPrimary.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Location Information & Map
                  if (_incident!.location != null) ...[
                    PremiumWidgets.premiumCard(
                      backgroundColor: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Location Details',
                                style: PremiumAppTheme.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_incident!.location!.address != null)
                            Text(
                              _incident!.location!.address!,
                              style: PremiumAppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (_incident!.location!.district != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'District: ${_incident!.location!.district}',
                                style: PremiumAppTheme.bodySmall.copyWith(
                                  color: PremiumAppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.gps_fixed, size: 14, color: PremiumAppTheme.textDisabled),
                              const SizedBox(width: 8),
                              Text(
                                '${_incident!.location!.latitude.toStringAsFixed(6)}, ${_incident!.location!.longitude.toStringAsFixed(6)}',
                                style: PremiumAppTheme.bodySmall.copyWith(
                                  color: PremiumAppTheme.textDisabled,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Map view
                    PremiumWidgets.premiumCard(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: PremiumAppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.map_rounded,
                                    color: PremiumAppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Incident Location',
                                  style: PremiumAppTheme.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 18,
                                  color: PremiumAppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: SizedBox(
                              height: 250,
                              width: double.infinity,
                              child: MapWidget(
                                userLocation: null,
                                incidents: [_incident!],
                                initialCenter: LatLng(
                                  _incident!.location!.latitude,
                                  _incident!.location!.longitude,
                                ),
                                initialZoom: 15.0,
                                showUserLocation: false,
                                showIncidents: true,
                                onIncidentTap: null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Incident Image
                  if (incidentImageUrl != null)
                    PremiumWidgets.premiumCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Text(
                              'Incident Photo',
                              style: PremiumAppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              incidentImageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 220,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: PremiumAppTheme.border,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 48,
                                          color: PremiumAppTheme.textDisabled,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed to load image',
                                          style: PremiumAppTheme.bodySmall.copyWith(
                                            color: PremiumAppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Incident Information
                  PremiumWidgets.premiumCard(
                    backgroundColor: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: PremiumAppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.info, color: PremiumAppTheme.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Incident Information',
                              style: PremiumAppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32, thickness: 0.5),
                        _buildInfoRow(
                          Icons.event,
                          'Reported',
                          _formatDateTime(_incident!.reportedAt),
                        ),
                        if (_incident!.updatedAt != null) ...[
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.update,
                            'Last Updated',
                            _formatDateTime(_incident!.updatedAt!),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.flag_outlined,
                          'Status',
                          _incident!.status.toUpperCase(),
                          valueColor: PremiumAppTheme.getStatusColor(_incident!.status),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.report_problem_outlined,
                          'Severity',
                          _incident!.severity.toUpperCase(),
                          valueColor: PremiumAppTheme.getSeverityColor(_incident!.severity),
                        ),
                        if (assignedTeamName != null) ...[
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.group, 'Assigned Team', assignedTeamName),
                        ],
                        if (assignedByName != null) ...[
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.person_pin, 'Assigned By', assignedByName),
                        ],
                      ],
                    ),
                  ),

                  if (_incident!.missions != null && _incident!.missions!.isNotEmpty)
                    PremiumWidgets.premiumCard(
                      backgroundColor: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  color: Colors.indigo,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Assigned Missions',
                                style: PremiumAppTheme.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ..._incident!.missions!.map((mission) {
                            final missionStatus = mission.missionStatus ?? 'assigned';
                            final statusColor = PremiumAppTheme.getStatusColor(missionStatus);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: PremiumAppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mission.rescueTeamName ?? 'Assigned Rescue Team',
                                          style: PremiumAppTheme.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Mission #${mission.missionId}',
                                          style: PremiumAppTheme.bodySmall.copyWith(
                                            color: PremiumAppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      missionStatus.toUpperCase(),
                                      style: PremiumAppTheme.labelSmall.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      final missionModel = _toMissionModel(mission);
                                      if (missionModel == null) return;
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.missionDetails,
                                        arguments: {'mission': missionModel},
                                      );
                                    },
                                    child: const Text('View'),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  // Reporter Information
                  if (_incident!.user != null) ...[
                    PremiumWidgets.premiumCard(
                      backgroundColor: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: PremiumAppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.person_pin_rounded,
                                  color: PremiumAppTheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Reported By',
                                style: PremiumAppTheme.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32, thickness: 0.5),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: PremiumAppTheme.primary.withValues(alpha: 0.1),
                                child: Text(
                                  _incident!.user!.name[0].toUpperCase(),
                                  style: PremiumAppTheme.titleMedium.copyWith(
                                    color: PremiumAppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _incident!.user!.name,
                                      style: PremiumAppTheme.bodyLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _incident!.user!.email,
                                      style: PremiumAppTheme.bodySmall.copyWith(
                                        color: PremiumAppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: PremiumAppTheme.border),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.mail_outline_rounded, size: 20),
                                  onPressed: () {},
                                  color: PremiumAppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
  }

  Widget _buildCommentsTab() {
    return Container(
      color: const Color(0xFFF0F4F8),
      child: Column(
        children: [
          Expanded(
            child: Consumer<CommentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.comments.isEmpty) {
                   return const Center(child: CircularProgressIndicator());
                }

                if (provider.comments.isEmpty) {
                   return PremiumWidgets.emptyState(
                     title: 'No Discussion',
                     message: 'Be the first to share an update or ask a question.',
                     icon: Icons.chat_bubble_outline_rounded,
                   );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: provider.comments.length,
                  itemBuilder: (context, index) {
                     final comment = provider.comments[index];
                     return _buildCommentItem(comment);
                  },
                );
              },
            )
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    final isRescueTeam = comment.userRole.toLowerCase().contains('rescue') || 
                         comment.userRole.toLowerCase().contains('admin');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isRescueTeam ? PremiumAppTheme.primaryLight.withValues(alpha: 0.1) : Colors.grey[200],
            child: Text(
              comment.userName[0].toUpperCase(),
              style: TextStyle(
                color: isRescueTeam ? PremiumAppTheme.primaryLight : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: PremiumAppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: PremiumAppTheme.textPrimary,
                      ),
                    ),
                    if (isRescueTeam) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: PremiumAppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OFFICIAL',
                          style: PremiumAppTheme.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatDateTime(comment.createdAt),
                      style: PremiumAppTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRescueTeam ? PremiumAppTheme.primary.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                      bottomLeft: const Radius.circular(16),
                      topLeft: isRescueTeam ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isRescueTeam ? PremiumAppTheme.primary.withValues(alpha: 0.2) : PremiumAppTheme.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    comment.content,
                    style: PremiumAppTheme.bodyMedium.copyWith(
                      color: PremiumAppTheme.textPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final textController = TextEditingController();

    return Container(
       padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
       decoration: BoxDecoration(
         color: Colors.white,
         boxShadow: [
           BoxShadow(
             color: Colors.black.withValues(alpha: 0.05),
             blurRadius: 10,
             offset: const Offset(0, -5),
           )
         ],
       ),
       child: Row(
         children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: PremiumAppTheme.border),
                ),
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                     hintText: 'Add an update or question...',
                     hintStyle: PremiumAppTheme.bodyMedium.copyWith(color: PremiumAppTheme.textDisabled),
                     border: InputBorder.none,
                     enabledBorder: InputBorder.none,
                     focusedBorder: InputBorder.none,
                     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  maxLines: 4,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: PremiumAppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PremiumAppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () {
                   if (textController.text.trim().isNotEmpty) {
                      Provider.of<CommentProvider>(context, listen: false)
                         .addComment(widget.incidentId!, textController.text.trim())
                         .then((_) => textController.clear())
                         .catchError((e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
                         });
                   }
                },
              ),
            ),
         ],
       ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = PremiumAppTheme.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: PremiumAppTheme.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    final color = PremiumAppTheme.getSeverityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            severity.toUpperCase(),
            style: PremiumAppTheme.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _statusGuidance(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'This report is awaiting review. Coordinators may verify details and assign rescue resources.';
      case 'verified':
        return 'This incident has been verified. A rescue team may be assigned next.';
      case 'assigned':
        return 'A rescue team is linked to this incident. Missions may be in progress.';
      case 'in_progress':
        return 'Response activities are underway.';
      case 'resolved':
      case 'closed':
        return 'This incident has been closed or resolved for coordination purposes.';
      default:
        return 'Status updates appear in the History tab as responders take action.';
    }
  }

  Widget _buildHistoryTab() {
    final updates = _incident?.incidentUpdates;
    if (updates == null || updates.isEmpty) {
      return PremiumWidgets.emptyState(
        title: 'No History Yet',
        message: 'Updates from administrators and rescue teams will appear here as they take action.',
        icon: Icons.history_toggle_off_rounded,
      );
    }

    final sorted = List.of(updates)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final u = sorted[index];
        final isFirst = index == 0;
        final isLast = index == sorted.length - 1;

        return _buildTimelineNode(u, isFirst, isLast);
      },
    );
  }

  Widget _buildTimelineNode(dynamic update, bool isFirst, bool isLast) {
    final statusColor = PremiumAppTheme.getStatusColor(update.status);
    
    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline Line and Dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : PremiumAppTheme.border,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : PremiumAppTheme.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PremiumAppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        update.status.toUpperCase(),
                        style: PremiumAppTheme.labelLarge.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDateTime(update.updatedAt),
                        style: PremiumAppTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (update.note != null && update.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      update.note!,
                      style: PremiumAppTheme.bodyMedium.copyWith(
                        color: PremiumAppTheme.textPrimary,
                      ),
                    ),
                  ],
                  if (update.imageUrl != null && update.imageUrl!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _resolveIncidentImageUrl(update.imageUrl)!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 80,
                          alignment: Alignment.center,
                          color: Colors.grey[100],
                          child: Text(
                            'Failed to load update image',
                            style: PremiumAppTheme.bodySmall.copyWith(
                              color: PremiumAppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: PremiumAppTheme.textSecondary.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: PremiumAppTheme.bodySmall.copyWith(
                  color: PremiumAppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: PremiumAppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? PremiumAppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  String? _resolveIncidentImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final imageUrl = raw.trim();

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    final baseHost = AppConfig.baseUrl.replaceFirst('/api', '');
    if (imageUrl.startsWith('/')) {
      return '$baseHost$imageUrl';
    }
    return '$baseHost/$imageUrl';
  }

  String? _assignedTeamName(IncidentModel incident) {
    if (incident.missions == null || incident.missions!.isEmpty) return null;
    final namedMission = incident.missions!.firstWhere(
      (m) => m.rescueTeamName != null && m.rescueTeamName!.trim().isNotEmpty,
      orElse: () => incident.missions!.first,
    );
    return namedMission.rescueTeamName;
  }

  String? _assignedByName(IncidentModel incident) {
    if (incident.missions == null || incident.missions!.isEmpty) return null;
    final missionWithUser = incident.missions!.firstWhere(
      (m) => m.assignedByName != null && m.assignedByName!.trim().isNotEmpty,
      orElse: () => incident.missions!.first,
    );
    return missionWithUser.assignedByName;
  }

  MissionModel? _toMissionModel(IncidentMission mission) {
    if (_incident == null) return null;

    final incidentInfo = MissionIncidentInfo(
      incidentId: _incident!.incidentId,
      title: _incident!.title,
      description: _incident!.description,
      severity: _incident!.severity,
      status: _incident!.status,
      location: _incident!.location,
      reporterName: _incident!.user?.name,
      reporterPhone: _incident!.user?.phone,
    );

    return MissionModel(
      missionId: mission.missionId,
      incidentId: _incident!.incidentId,
      rescueTeamId: mission.rescueTeamId,
      missionStatus: mission.missionStatus ?? 'assigned',
      assignedAt: mission.assignedAt ?? _incident!.reportedAt,
      completedAt: mission.completedAt,
      incident: incidentInfo,
      rescueTeam: mission.rescueTeamName != null
          ? RescueTeamInfo(
              teamId: mission.rescueTeamId ?? 0,
              teamName: mission.rescueTeamName!,
            )
          : null,
    );
  }
}

