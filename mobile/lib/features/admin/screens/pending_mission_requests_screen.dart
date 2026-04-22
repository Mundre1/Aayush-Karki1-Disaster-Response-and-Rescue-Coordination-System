import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/widgets/admin_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/premium_widgets.dart';

class PendingMissionRequestsScreen extends StatefulWidget {
  const PendingMissionRequestsScreen({super.key});

  @override
  State<PendingMissionRequestsScreen> createState() =>
      _PendingMissionRequestsScreenState();
}

class _PendingMissionRequestsScreenState
    extends State<PendingMissionRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadVolunteerMissionRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final list = admin.volunteerMissionRequests;

    return Scaffold(
      backgroundColor: PremiumAppTheme.background,
      appBar: AdminAppBar(
        title: 'Mission Requests',
        showDrawerButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => admin.loadVolunteerMissionRequests(),
          ),
        ],
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminMissionRequests),
      body: Column(
        children: [
          // Premium Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: BoxDecoration(
              color: PremiumAppTheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personnel Dispatch',
                  style: PremiumAppTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verify and approve volunteer participation requests.',
                  style: PremiumAppTheme.bodySmall.copyWith(color: PremiumAppTheme.textSecondary),
                ),
              ],
            ),
          ),

          Expanded(
            child: admin.loadingMissionRequests
                ? PremiumWidgets.loadingIndicator(message: 'Syncing mission requests...')
                : list.isEmpty
                    ? PremiumWidgets.emptyState(
                        title: 'No Pending Requests',
                        message: 'All volunteer mission requests have been processed.',
                        icon: Icons.assignment_turned_in_rounded,
                      )
                    : RefreshIndicator(
                        onRefresh: () => admin.loadVolunteerMissionRequests(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final row = list[index];
                            final rawRid = row['requestId'] ?? row['request_id'];
                            final requestId = rawRid is int
                                ? rawRid
                                : int.tryParse(rawRid.toString()) ?? 0;
                            final volunteer = row['volunteer'] as Map<String, dynamic>?;
                            final mission = row['mission'] as Map<String, dynamic>?;
                            final incident = mission?['incident'] as Map<String, dynamic>?;
                            final name = volunteer?['name'] ?? volunteer?['email'] ?? 'Anonymous';
                            final title = incident?['title'] ?? 'Active Mission';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: PremiumAppTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: PremiumAppTheme.border, width: 0.5),
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
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: PremiumAppTheme.background,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.person_pin_circle_rounded,
                                                color: PremiumAppTheme.primary,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: PremiumAppTheme.titleMedium.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Volunteer applicant',
                                                    style: PremiumAppTheme.labelSmall.copyWith(
                                                      color: PremiumAppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'Applying for:',
                                          style: PremiumAppTheme.labelSmall.copyWith(letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          title,
                                          style: PremiumAppTheme.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: PremiumAppTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Mission ID: #${mission?['missionId'] ?? mission?['mission_id']}',
                                          style: PremiumAppTheme.bodySmall.copyWith(color: PremiumAppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: PremiumAppTheme.background.withValues(alpha: 0.5),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(20),
                                        bottomRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              final r = await admin.approveMissionRequest(requestId);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(r['message']?.toString() ?? 'Approved'),
                                                    backgroundColor: PremiumAppTheme.success,
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.verified_user_rounded, size: 18),
                                            label: const Text('Approve'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: PremiumAppTheme.success,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, height: 24, color: PremiumAppTheme.border),
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              if (requestId == 0) return;
                                              final r = await admin.rejectMissionRequest(requestId);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(r['message']?.toString() ?? 'Rejected'),
                                                    backgroundColor: PremiumAppTheme.emergency,
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.block_rounded, size: 18),
                                            label: const Text('Reject'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: PremiumAppTheme.emergency,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
}
