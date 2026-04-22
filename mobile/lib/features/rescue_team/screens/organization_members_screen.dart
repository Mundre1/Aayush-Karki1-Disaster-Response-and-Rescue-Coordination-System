import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../rescue_team_provider.dart';

class OrganizationMembersScreen extends StatefulWidget {
  const OrganizationMembersScreen({super.key});

  @override
  State<OrganizationMembersScreen> createState() =>
      _OrganizationMembersScreenState();
}

class _OrganizationMembersScreenState extends State<OrganizationMembersScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = context.read<RescueTeamProvider>();
    final result = await provider.loadOrganizationMembers();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] != true) {
        _error = result['message']?.toString() ?? 'Failed to load members';
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return PremiumAppTheme.success;
      case 'rejected':
        return PremiumAppTheme.emergency;
      default:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RescueTeamProvider>();
    final members = provider.organizationMembers;
    return Scaffold(
      appBar: PremiumAppBar(title: 'Organization Members'),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: _loading
            ? PremiumWidgets.loadingIndicator(message: 'Loading members...')
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      PremiumWidgets.emptyState(
                        title: 'Failed to load members',
                        message: _error!,
                        icon: Icons.error_outline,
                        buttonText: 'Retry',
                        onAction: _loadMembers,
                      ),
                    ],
                  )
                : members.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          PremiumWidgets.emptyState(
                            title: 'No members found',
                            message:
                                'No members are linked to this organization yet.',
                            icon: Icons.groups_outlined,
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final status =
                              member['responderStatus']?.toString() ?? 'pending';
                          final color = _statusColor(status);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PremiumWidgets.premiumCard(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.shade50,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member['name']?.toString() ??
                                              'Unknown member',
                                          style: PremiumAppTheme.titleMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          member['email']?.toString() ?? '',
                                          style: PremiumAppTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: color),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: PremiumAppTheme.labelSmall.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
