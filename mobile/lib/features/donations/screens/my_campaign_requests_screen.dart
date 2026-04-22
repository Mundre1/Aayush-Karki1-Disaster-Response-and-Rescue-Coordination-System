import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../auth/auth_provider.dart';
import '../campaign_provider.dart';
import '../models/campaign_model.dart';

class MyCampaignRequestsScreen extends StatefulWidget {
  const MyCampaignRequestsScreen({super.key});

  @override
  State<MyCampaignRequestsScreen> createState() => _MyCampaignRequestsScreenState();
}

class _MyCampaignRequestsScreenState extends State<MyCampaignRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadRequests();
    });
  }

  Future<void> _loadRequests() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.userId;
    if (userId == null) return;
    await context.read<CampaignProvider>().loadMyCampaignRequests(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(title: 'My Campaign Requests'),
      body: Consumer<CampaignProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.myCampaigns.isEmpty) {
            return PremiumWidgets.loadingIndicator(message: 'Loading your requests...');
          }

          if (provider.error != null && provider.myCampaigns.isEmpty) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: _loadRequests,
            );
          }

          if (provider.myCampaigns.isEmpty) {
            return PremiumWidgets.emptyState(
              title: 'No campaign requests yet',
              message: 'Submit a campaign request and track its review status here.',
              icon: Icons.campaign_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRequests,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myCampaigns.length,
              itemBuilder: (context, index) {
                final campaign = provider.myCampaigns[index];
                return _MyCampaignRequestCard(campaign: campaign);
              },
            ),
          );
        },
      ),
    );
  }
}

class _MyCampaignRequestCard extends StatelessWidget {
  const _MyCampaignRequestCard({required this.campaign});

  final CampaignModel campaign;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blueGrey;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'PENDING';
    return status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(campaign.status);
    return PremiumWidgets.premiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  campaign.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(campaign.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            campaign.description,
            style: TextStyle(color: Colors.grey[700], height: 1.35),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Target: \$${campaign.targetAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Raised: \$${campaign.raisedAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Submitted: ${DateFormat('MMM d, yyyy').format(campaign.createdAt)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PremiumWidgets.statusIndicator(
            status: campaign.status,
            text: _statusLabel(campaign.status),
            size: 8,
          ),
        ],
      ),
    );
  }
}
