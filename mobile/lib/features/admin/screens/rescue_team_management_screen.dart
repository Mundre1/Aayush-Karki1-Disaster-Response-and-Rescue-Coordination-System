import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/widgets/admin_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import 'organization_details_screen.dart';

class RescueTeamManagementScreen extends StatefulWidget {
  const RescueTeamManagementScreen({super.key});

  @override
  State<RescueTeamManagementScreen> createState() =>
      _RescueTeamManagementScreenState();
}

class _RescueTeamManagementScreenState
    extends State<RescueTeamManagementScreen> {
  bool? _filterActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadRescueTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final teams = adminProvider.rescueTeams;
    final filteredTeams = _filterActive == null
        ? teams
        : teams
              .where((t) => (t['isActive'] ?? t['is_active']) == _filterActive)
              .toList();

    return Scaffold(
      appBar: AdminAppBar(
        title: 'Organizations',
        showDrawerButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              adminProvider.loadRescueTeams();
            },
          ),
        ],
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminRescueTeams),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: BoxDecoration(
              color: PremiumAppTheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Responder Teams',
                  style: PremiumAppTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Teams',
                        isSelected: _filterActive == null,
                        onSelected: () => setState(() => _filterActive = null),
                        activeColor: PremiumAppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Active',
                        isSelected: _filterActive == true,
                        onSelected: () => setState(() => _filterActive = true),
                        activeColor: PremiumAppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Inactive',
                        isSelected: _filterActive == false,
                        onSelected: () => setState(() => _filterActive = false),
                        activeColor: PremiumAppTheme.neutral,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Teams list
          Expanded(
            child: adminProvider.isLoadingRescueTeams
                ? PremiumWidgets.loadingIndicator(
                    message: 'Fetching organizations...',
                  )
                : adminProvider.rescueTeamsError != null
                ? PremiumWidgets.emptyState(
                    title: 'Sync Error',
                    message: adminProvider.rescueTeamsError!,
                    icon: Icons.sync_problem_rounded,
                    buttonText: 'Retry',
                    onAction: () => adminProvider.loadRescueTeams(),
                  )
                : filteredTeams.isEmpty
                ? PremiumWidgets.emptyState(
                    title: 'No Results',
                    message: _filterActive != null
                        ? 'No teams match the current filter.'
                        : 'No organizations have been onboarded yet.',
                    icon: Icons.groups_rounded,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await adminProvider.loadRescueTeams();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: filteredTeams.length,
                      itemBuilder: (context, index) {
                        final team = filteredTeams[index];
                        final teamName =
                            team['teamName'] ??
                            team['team_name'] ??
                            'Unknown Team';
                        final isActive =
                            team['isActive'] ?? team['is_active'] ?? false;
                        final contactInfo =
                            team['contact'] ??
                            team['contactInfo'] ??
                            team['contact_info'] ??
                            'No contact info';

                        return PremiumWidgets.modernListItem(
                          title: teamName,
                          subtitle: contactInfo,
                          onTap: () {
                            final orgId = team['organizationId'] ??
                                team['teamId'] ??
                                team['organization_id'] ??
                                team['team_id'];
                            final parsedId = orgId is int
                                ? orgId
                                : int.tryParse(orgId?.toString() ?? '');
                            if (parsedId == null) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrganizationDetailsScreen(
                                  organizationId: parsedId,
                                ),
                              ),
                            );
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isActive
                                      ? PremiumAppTheme.success
                                      : PremiumAppTheme.neutral)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.business_center_rounded,
                              color: isActive
                                  ? PremiumAppTheme.success
                                  : PremiumAppTheme.neutral,
                              size: 24,
                            ),
                          ),
                          trailing: PremiumWidgets.statusIndicator(
                            status: isActive ? 'resolved' : 'closed',
                            text: isActive ? 'Active' : 'Inactive',
                            size: 8,
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color activeColor,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: activeColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? activeColor : PremiumAppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? activeColor.withValues(alpha: 0.5) : PremiumAppTheme.border,
        ),
      ),
      showCheckmark: false,
    );
  }
}
