import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/widgets/admin_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';

class VolunteerManagementScreen extends StatefulWidget {
  const VolunteerManagementScreen({super.key});

  @override
  State<VolunteerManagementScreen> createState() =>
      _VolunteerManagementScreenState();
}

class _VolunteerManagementScreenState extends State<VolunteerManagementScreen> {
  bool? _filterApproved;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadVolunteers();
    });
  }

  Future<void> _approveVolunteer(int volunteerId) async {
    final adminProvider = context.read<AdminProvider>();
    final result = await adminProvider.approveVolunteer(volunteerId);

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
              Expanded(child: Text(result['message'] ?? 'Operation completed')),
            ],
          ),
          backgroundColor: result['success'] == true
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final volunteers = adminProvider.volunteers;
    final filteredVolunteers = _filterApproved == null
        ? volunteers
        : volunteers
              .where(
                (v) => (v['isApproved'] ?? v['is_approved']) == _filterApproved,
              )
              .toList();

    return Scaffold(
      appBar: AdminAppBar(
        title: 'Volunteers',
        showDrawerButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              adminProvider.loadVolunteers();
            },
          ),
        ],
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminVolunteers),
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
                  'User Verification',
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
                        label: 'All Users',
                        isSelected: _filterApproved == null,
                        onSelected: () => setState(() => _filterApproved = null),
                        activeColor: PremiumAppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Pending',
                        isSelected: _filterApproved == false,
                        onSelected: () => setState(() => _filterApproved = false),
                        activeColor: PremiumAppTheme.warning,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Approved',
                        isSelected: _filterApproved == true,
                        onSelected: () => setState(() => _filterApproved = true),
                        activeColor: PremiumAppTheme.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Volunteers list
          Expanded(
            child: adminProvider.isLoadingVolunteers
                ? PremiumWidgets.loadingIndicator(
                    message: 'Fetching volunteer data...',
                  )
                : adminProvider.volunteersError != null
                ? PremiumWidgets.emptyState(
                    title: 'Connection Issue',
                    message: adminProvider.volunteersError!,
                    icon: Icons.wifi_off_rounded,
                    buttonText: 'Retry',
                    onAction: () => adminProvider.loadVolunteers(),
                  )
                : filteredVolunteers.isEmpty
                ? PremiumWidgets.emptyState(
                    title: 'No Volunteers',
                    message: _filterApproved != null
                        ? 'No users match this criteria.'
                        : 'No volunteers have joined the platform yet.',
                    icon: Icons.person_search_rounded,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await adminProvider.loadVolunteers();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: filteredVolunteers.length,
                      itemBuilder: (context, index) {
                        final volunteer = filteredVolunteers[index];
                        final volunteerId =
                            volunteer['volunteerId'] ??
                            volunteer['volunteer_id'];
                        final user = volunteer['user'] as Map<String, dynamic>?;
                        final name = user?['name'] ?? 'Anonymous';
                        final email = user?['email'] ?? 'No email';
                        final isApproved =
                            volunteer['isApproved'] ??
                            volunteer['is_approved'] ??
                            false;
                        final skills = volunteer['skills']?.toString() ?? 'General';

                        return PremiumWidgets.modernListItem(
                          title: name,
                          subtitle: '$email\nSkills: $skills',
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: (isApproved
                                    ? PremiumAppTheme.success
                                    : PremiumAppTheme.warning)
                                .withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: isApproved
                                  ? PremiumAppTheme.success
                                  : PremiumAppTheme.warning,
                            ),
                          ),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 104),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: isApproved
                                    ? PremiumWidgets.statusIndicator(
                                        status: 'resolved',
                                        text: 'Verified',
                                        size: 8,
                                      )
                                    : PremiumWidgets.premiumButton(
                                        text: 'Approve',
                                        onPressed: () =>
                                            _approveVolunteer(volunteerId),
                                        width: 84,
                                        height: 34,
                                        backgroundColor:
                                            PremiumAppTheme.primary,
                                        icon: Icons.verified_rounded,
                                      ),
                              ),
                            ),
                          ),
                          onTap: () {
                            // View detailed volunteer profile if available
                          },
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
