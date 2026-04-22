import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/admin_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../admin_provider.dart';
import '../widgets/admin_drawer.dart';

class PendingResponderApprovalsScreen extends StatefulWidget {
  const PendingResponderApprovalsScreen({super.key});

  @override
  State<PendingResponderApprovalsScreen> createState() =>
      _PendingResponderApprovalsScreenState();
}

class _PendingResponderApprovalsScreenState
    extends State<PendingResponderApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadPendingResponderApprovals();
    });
  }

  Future<void> _reviewResponder(
    BuildContext context,
    AdminProvider provider,
    int userId,
    bool approve,
  ) async {
    final result = await provider.reviewResponder(
      responderUserId: userId,
      approve: approve,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message']?.toString() ?? 'Done')),
    );
  }

  Future<void> _reviewOrganization(
    BuildContext context,
    AdminProvider provider,
    int organizationId,
    bool approve,
  ) async {
    final result = await provider.reviewOrganization(
      organizationId: organizationId,
      approve: approve,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message']?.toString() ?? 'Done')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: PremiumAppTheme.background,
          appBar: const AdminAppBar(
            title: 'Responder Approvals',
            showDrawerButton: true,
          ),
          drawer: const AdminDrawer(currentRoute: AppRoutes.adminResponderApprovals),
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
                      'Access Management',
                      style: PremiumAppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review and grant system access to teams and responders.',
                      style: PremiumAppTheme.bodySmall.copyWith(color: PremiumAppTheme.textSecondary),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.loadPendingResponderApprovals,
                  child: provider.loadingResponderApprovals
                      ? PremiumWidgets.loadingIndicator(message: 'Loading requests...')
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          children: [
                            PremiumWidgets.sectionHeader(
                              title: 'Organizations',
                              subtitle: 'Team account requests',
                            ),
                            const SizedBox(height: 12),
                            if (provider.pendingOrganizations.isEmpty)
                              PremiumWidgets.emptyState(
                                title: 'No Pending Organizations',
                                message: 'New organization requests will appear here.',
                                icon: Icons.business_rounded,
                              )
                            else
                              ...provider.pendingOrganizations.map((org) => _buildOrgCard(context, provider, org)),
                            
                            const SizedBox(height: 32),
                            
                            PremiumWidgets.sectionHeader(
                              title: 'Individual Responders',
                              subtitle: 'Personnel access requests',
                            ),
                            const SizedBox(height: 12),
                            if (provider.pendingResponders.isEmpty)
                              PremiumWidgets.emptyState(
                                title: 'No Pending Responders',
                                message: 'Individual responder requests will appear here.',
                                icon: Icons.person_add_rounded,
                              )
                            else
                              ...provider.pendingResponders.map((user) => _buildResponderCard(context, provider, user)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrgCard(BuildContext context, AdminProvider provider, Map<String, dynamic> org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PremiumAppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumAppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PremiumAppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.apartment_rounded, color: PremiumAppTheme.primary),
            ),
            title: Text(
              org['organizationName']?.toString() ?? 'Organization',
              style: PremiumAppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Contact: ${org['contact']?.toString() ?? '-'}',
              style: PremiumAppTheme.bodySmall.copyWith(color: PremiumAppTheme.textSecondary),
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
                  child: TextButton(
                    onPressed: () => _reviewOrganization(context, provider, org['organizationId'] as int, false),
                    style: TextButton.styleFrom(foregroundColor: PremiumAppTheme.emergency),
                    child: const Text('Reject'),
                  ),
                ),
                Container(width: 1, height: 24, color: PremiumAppTheme.border),
                Expanded(
                  child: TextButton(
                    onPressed: () => _reviewOrganization(context, provider, org['organizationId'] as int, true),
                    style: TextButton.styleFrom(foregroundColor: PremiumAppTheme.success),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponderCard(BuildContext context, AdminProvider provider, Map<String, dynamic> user) {
    final org = user['organization'] as Map<String, dynamic>?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PremiumAppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumAppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PremiumAppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline_rounded, color: PremiumAppTheme.primary),
            ),
            title: Text(
              user['name']?.toString() ?? 'Responder',
              style: PremiumAppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email']?.toString() ?? ''),
                if (org != null)
                  Text(
                    'Org: ${org['organizationName']?.toString() ?? '-'}',
                    style: PremiumAppTheme.labelSmall.copyWith(color: PremiumAppTheme.textSecondary),
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
                  child: TextButton(
                    onPressed: () => _reviewResponder(context, provider, user['userId'] as int, false),
                    style: TextButton.styleFrom(foregroundColor: PremiumAppTheme.emergency),
                    child: const Text('Reject'),
                  ),
                ),
                Container(width: 1, height: 24, color: PremiumAppTheme.border),
                Expanded(
                  child: TextButton(
                    onPressed: () => _reviewResponder(context, provider, user['userId'] as int, true),
                    style: TextButton.styleFrom(foregroundColor: PremiumAppTheme.success),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
