import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../incidents/models/incident_model.dart';
import '../admin_provider.dart';
import '../widgets/assign_team_dialog.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/widgets/admin_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';

class IncidentManagementScreen extends StatefulWidget {
  final int? incidentId;

  const IncidentManagementScreen({super.key, this.incidentId});

  @override
  State<IncidentManagementScreen> createState() =>
      _IncidentManagementScreenState();
}

class _IncidentManagementScreenState extends State<IncidentManagementScreen> {
  String? _selectedStatus;
  String? _selectedSeverity;
  final TextEditingController _searchController = TextEditingController();

  List<IncidentModel> _getFilteredIncidents(List<IncidentModel> allIncidents) {
    final search = _searchController.text.toLowerCase();
    return allIncidents.where((incident) {
      final matchesStatus =
          _selectedStatus == null || incident.status == _selectedStatus;
      final matchesSeverity =
          _selectedSeverity == null || incident.severity == _selectedSeverity;
      final matchesSearch =
          search.isEmpty ||
          incident.title.toLowerCase().contains(search) ||
          incident.description.toLowerCase().contains(search);
      return matchesStatus && matchesSeverity && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadAllIncidents();
    });
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteIncident(IncidentModel incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Incident'),
        content: Text('Are you sure you want to delete "${incident.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final adminProvider = context.read<AdminProvider>();
      final result = await adminProvider.deleteIncident(incident.incidentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result['success'] == true ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(result['message'] ?? 'Operation completed'),
                ),
              ],
            ),
            backgroundColor: result['success'] == true
                ? Colors.green
                : Colors.red,
          ),
        );
        setState(() {});
      }
    }
  }

  Future<void> _assignTeam(IncidentModel incident) async {
    final result = await AssignTeamDialog.show(context, incident.incidentId);
    if (result != null && mounted) {
      setState(() {});
    }
  }

  Future<void> _verifyIncident(IncidentModel incident) async {
    final adminProvider = context.read<AdminProvider>();
    final result = await adminProvider.verifyIncident(incident.incidentId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Done'),
        backgroundColor:
            result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final allIncidents = adminProvider.allIncidents;
    final filteredIncidents = _getFilteredIncidents(allIncidents);

    return Scaffold(
      appBar: AdminAppBar(
        title: 'Incident Management',
        subtitle: 'Filter and assign responder organizations',
        showDrawerButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              adminProvider.loadAllIncidents();
            },
          ),
        ],
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminIncidents),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: PremiumAppTheme.surface,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search incidents...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'All Status',
                        _selectedStatus == null,
                        () => setState(() {
                          _selectedStatus = null;
                        }),
                      ),
                      _buildFilterChip(
                        'Pending',
                        _selectedStatus == 'pending',
                        () => setState(() {
                          _selectedStatus = 'pending';
                        }),
                      ),
                      _buildFilterChip(
                        'In Progress',
                        _selectedStatus == 'in_progress',
                        () => setState(() {
                          _selectedStatus = 'in_progress';
                        }),
                      ),
                      _buildFilterChip(
                        'Resolved',
                        _selectedStatus == 'resolved',
                        () => setState(() {
                          _selectedStatus = 'resolved';
                        }),
                      ),
                      _buildFilterChip(
                        'Verified',
                        _selectedStatus == 'verified',
                        () => setState(() {
                          _selectedStatus = 'verified';
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'All Severity',
                        _selectedSeverity == null,
                        () => setState(() {
                          _selectedSeverity = null;
                        }),
                      ),
                      _buildFilterChip(
                        'Critical',
                        _selectedSeverity == 'critical',
                        () => setState(() {
                          _selectedSeverity = 'critical';
                        }),
                      ),
                      _buildFilterChip(
                        'High',
                        _selectedSeverity == 'high',
                        () => setState(() {
                          _selectedSeverity = 'high';
                        }),
                      ),
                      _buildFilterChip(
                        'Medium',
                        _selectedSeverity == 'medium',
                        () => setState(() {
                          _selectedSeverity = 'medium';
                        }),
                      ),
                      _buildFilterChip(
                        'Low',
                        _selectedSeverity == 'low',
                        () => setState(() {
                          _selectedSeverity = 'low';
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Incidents list
          Expanded(
            child: adminProvider.isLoadingIncidents
                ? PremiumWidgets.loadingIndicator(
                    message: 'Loading incidents...',
                  )
                : adminProvider.incidentsError != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: PremiumAppTheme.textDisabled,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          adminProvider.incidentsError!,
                          style: PremiumAppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : filteredIncidents.isEmpty
                ? PremiumWidgets.emptyState(
                    title: 'No Incidents Found',
                    message:
                        _selectedStatus != null ||
                            _selectedSeverity != null ||
                            _searchController.text.isNotEmpty
                        ? 'Try adjusting your filters'
                        : 'No incidents have been reported yet.',
                    icon: Icons.inbox_rounded,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await adminProvider.loadAllIncidents();
                      setState(() {});
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredIncidents.length,
                      itemBuilder: (context, index) {
                        final incident = filteredIncidents[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PremiumWidgets.incidentCard(
                            title: incident.title,
                            description: incident.description,
                            location: incident.location?.address ?? 'Unknown',
                            status: incident.status,
                            severity: incident.severity,
                            imageUrl: incident.imageUrl,
                            reportedAt: incident.reportedAt,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.incidentDetails,
                                arguments: {'incidentId': incident.incidentId},
                              );
                            },
                            actions: [_buildIncidentActions(incident)],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.red.shade100,
        checkmarkColor: Colors.red.shade700,
        labelStyle: TextStyle(
          color: isSelected ? Colors.red.shade700 : PremiumAppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildIncidentActions(IncidentModel incident) {
    final canAssignTeam =
        (incident.status == 'pending' || incident.status == 'verified') &&
        (incident.missionIds == null || incident.missionIds!.isEmpty);

    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            if (incident.status == 'pending')
              PremiumWidgets.premiumButton(
                text: 'Verify',
                onPressed: () => _verifyIncident(incident),
                height: 36,
                backgroundColor: Colors.teal.shade700,
                icon: Icons.verified_outlined,
              ),
            if (canAssignTeam)
              PremiumWidgets.premiumButton(
                text: 'Assign Team',
                onPressed: () => _assignTeam(incident),
                height: 36,
                backgroundColor: Colors.blue.shade700,
                icon: Icons.group_add,
              ),
            PremiumWidgets.premiumButton(
              text: 'Delete',
              onPressed: () => _deleteIncident(incident),
              height: 36,
              backgroundColor: Colors.red.shade700,
              icon: Icons.delete,
            ),
          ],
        ),
      ),
    );
  }
}
