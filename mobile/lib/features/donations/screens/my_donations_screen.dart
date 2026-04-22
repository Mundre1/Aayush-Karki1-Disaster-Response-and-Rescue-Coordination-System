import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../donation_provider.dart';
import '../models/donation_model.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<DonationProvider>(context, listen: false).loadMyDonations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(title: 'My Donations'),
      body: Consumer<DonationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return PremiumWidgets.loadingIndicator(message: 'Loading your donations...');
          }

          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.loadMyDonations(),
            );
          }

          if (provider.myDonations.isEmpty) {
            return PremiumWidgets.emptyState(
              title: 'No donations yet',
              message: 'Your donation history will appear here.',
              icon: Icons.volunteer_activism,
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadMyDonations(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myDonations.length,
              itemBuilder: (context, index) {
                final donation = provider.myDonations[index];
                return _buildDonationCard(donation);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(DonationModel donation) {
    return PremiumWidgets.premiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showDonationDetails(donation),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  donation.campaignTitle ?? 'General Donation',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                NumberFormat.currency(symbol: '\$').format(donation.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              PremiumWidgets.statusIndicator(
                status: donation.status,
                text: donation.status,
                size: 8,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                DateFormat.yMMMd().add_jm().format(donation.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          if (donation.transactionId != null) ...[
            const SizedBox(height: 4),
            Text(
              'ID: ${donation.transactionId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  void _showDonationDetails(DonationModel donation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Donation Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    PremiumWidgets.statusIndicator(
                      status: donation.status,
                      text: donation.status,
                      size: 8,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow('Campaign', donation.campaignTitle ?? 'General Donation'),
                _detailRow('Amount', NumberFormat.currency(symbol: '\$').format(donation.amount)),
                _detailRow('Date', DateFormat.yMMMMd().add_jm().format(donation.createdAt)),
                _detailRow('Payment method', donation.paymentMethod ?? 'N/A'),
                _detailRow('Donation ID', donation.id.toString()),
                if (donation.transactionId != null && donation.transactionId!.isNotEmpty)
                  _detailRow('Transaction ID', donation.transactionId!),
                if (donation.bankReference != null && donation.bankReference!.isNotEmpty)
                  _detailRow('Bank Reference', donation.bankReference!),
                if (donation.donorName != null && donation.donorName!.isNotEmpty)
                  _detailRow('Donor Name', donation.donorName!),
                if (donation.donorEmail != null && donation.donorEmail!.isNotEmpty)
                  _detailRow('Donor Email', donation.donorEmail!),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
