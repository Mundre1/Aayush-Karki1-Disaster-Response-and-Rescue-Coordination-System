import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/routes/app_routes.dart';
import '../../donations/campaign_provider.dart';
import '../../donations/models/campaign_model.dart';
import '../../../core/theme/app_theme.dart';

class AdminCampaignManagementScreen extends StatefulWidget {
  const AdminCampaignManagementScreen({super.key});

  @override
  State<AdminCampaignManagementScreen> createState() => _AdminCampaignManagementScreenState();
}

class _AdminCampaignManagementScreenState extends State<AdminCampaignManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CampaignProvider>().loadPendingCampaigns();
      context.read<CampaignProvider>().loadActiveCampaigns();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumAppTheme.background,
      appBar: AdminAppBar(
        title: 'Campaign Management',
        showDrawerButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              final provider = context.read<CampaignProvider>();
              await provider.loadPendingCampaigns();
              await provider.loadActiveCampaigns();
            },
          ),
        ],
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminCampaignManagement),
      body: Consumer<CampaignProvider>(
        builder: (context, provider, _) {
          return Column(
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
                      'Fundraising Oversight',
                      style: PremiumAppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review and approve community-driven rescue campaigns.',
                      style: PremiumAppTheme.bodySmall.copyWith(color: PremiumAppTheme.textSecondary),
                    ),
                  ],
                ),
              ),

              // Custom TabBar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PremiumAppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PremiumAppTheme.border, width: 0.5),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: PremiumAppTheme.textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: PremiumAppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Pending Review'),
                    Tab(text: 'Active Campaigns'),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CampaignListSection(
                      campaigns: provider.pendingCampaigns,
                      emptyTitle: 'No Pending Requests',
                      emptyMessage: 'All submitted campaigns have been reviewed.',
                      onRefresh: provider.loadPendingCampaigns,
                      showActions: true,
                      isLoading: provider.isLoading,
                    ),
                    _CampaignListSection(
                      campaigns: provider.activeCampaigns,
                      emptyTitle: 'No Active Campaigns',
                      emptyMessage: 'There are currently no live fundraising campaigns.',
                      onRefresh: provider.loadActiveCampaigns,
                      showActions: false,
                      isLoading: provider.isLoading,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CampaignListSection extends StatelessWidget {
  final List<CampaignModel> campaigns;
  final String emptyTitle;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final bool showActions;
  final bool isLoading;

  const _CampaignListSection({
    required this.campaigns,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onRefresh,
    required this.showActions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && campaigns.isEmpty) {
      return PremiumWidgets.loadingIndicator(message: 'Loading campaigns...');
    }

    if (campaigns.isEmpty) {
      return PremiumWidgets.emptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: Icons.campaign_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return _CampaignRequestCard(
            campaign: campaign,
            showActions: showActions,
          );
        },
      ),
    );
  }
}

class _CampaignRequestCard extends StatelessWidget {
  final CampaignModel campaign;
  final bool showActions;

  const _CampaignRequestCard({
    required this.campaign,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CampaignProvider>();

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        campaign.title,
                        style: PremiumAppTheme.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    PremiumWidgets.statusIndicator(
                      status: showActions ? 'pending' : 'resolved',
                      text: showActions ? 'PENDING' : 'ACTIVE',
                      size: 8,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: PremiumAppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'By ${campaign.creatorName ?? 'User'}',
                      style: PremiumAppTheme.bodySmall.copyWith(color: PremiumAppTheme.textSecondary),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  'Goal Target',
                  style: PremiumAppTheme.labelSmall.copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$${campaign.targetAmount.toStringAsFixed(2)}',
                      style: PremiumAppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: PremiumAppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.account_balance_wallet_rounded, color: PremiumAppTheme.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  campaign.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: PremiumAppTheme.bodyMedium.copyWith(height: 1.5, color: PremiumAppTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (showActions)
            Container(
              padding: const EdgeInsets.all(12),
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
                    child: OutlinedButton(
                      onPressed: () => _showConfirmDialog(context, false, provider),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PremiumAppTheme.emergency,
                        side: const BorderSide(color: PremiumAppTheme.emergency),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumWidgets.premiumButton(
                      text: 'Approve',
                      onPressed: () => _showConfirmDialog(context, true, provider),
                      backgroundColor: PremiumAppTheme.success,
                      height: 44,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, bool approve, CampaignProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Campaign?' : 'Decline Campaign?'),
        content: Text(
          approve
              ? 'This will make the campaign public for everyone to donate. The creator will be notified.'
              : 'Are you sure you want to decline this request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          PremiumWidgets.premiumButton(
            text: approve ? 'Approve' : 'Decline',
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (approve) {
                  await provider.approveCampaign(campaign.id);
                } else {
                  await provider.rejectCampaign(campaign.id);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(approve ? 'Campaign approved!' : 'Campaign declined.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: approve ? PremiumAppTheme.success : PremiumAppTheme.emergency,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: PremiumAppTheme.emergency,
                    ),
                  );
                }
              }
            },
            width: 100,
            height: 40,
            backgroundColor: approve ? PremiumAppTheme.success : PremiumAppTheme.emergency,
          ),
        ],
      ),
    );
  }
}


