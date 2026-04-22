import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/routes/app_routes.dart';
import '../campaign_provider.dart';
import '../models/campaign_model.dart';
import 'donation_form_screen.dart';
import 'my_campaign_requests_screen.dart';
import 'request_campaign_screen.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CampaignProvider>().loadActiveCampaigns();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(title: 'Support the Cause'),
      body: Consumer<CampaignProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.activeCampaigns.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: provider.loadActiveCampaigns,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Raise Funds CTA
                  _buildRaiseFundsCTA(context),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Active Campaigns',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (provider.activeCampaigns.isEmpty)
                     const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('No active campaigns at the moment.'),
                      ),
                    )
                  else
                    ...provider.activeCampaigns.map((c) => _CampaignListItem(campaign: c)),
                    
                  const SizedBox(height: 80), // Space for FAB-like bottom room
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRaiseFundsCTA(BuildContext context) {
    return AppCard(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Want to raise funds?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Start your own campaign to help victims in your area.',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RequestCampaignScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Request Campaign'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyCampaignRequestsScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('My Requests'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.myDonations),
                icon: const Icon(Icons.history),
                label: const Text('View My Donations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignListItem extends StatelessWidget {
  final CampaignModel campaign;

  const _CampaignListItem({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DonationFormScreen(campaign: campaign),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mock Image for now
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1469571486292-0ba58a3f068b?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          campaign.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${(campaign.progressPercentage * 100).toInt()}%',
                        style: TextStyle(
                          color: PremiumAppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    campaign.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: campaign.progressPercentage,
                      minHeight: 8,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(PremiumAppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${campaign.raisedAmount.toStringAsFixed(0)} raised',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Target: \$${campaign.targetAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
