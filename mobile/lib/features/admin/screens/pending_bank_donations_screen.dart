import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/widgets/admin_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';

class PendingBankDonationsScreen extends StatefulWidget {
  const PendingBankDonationsScreen({super.key});

  @override
  State<PendingBankDonationsScreen> createState() =>
      _PendingBankDonationsScreenState();
}

class _PendingBankDonationsScreenState extends State<PendingBankDonationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadPendingBankDonations();
      context.read<AdminProvider>().loadAllDonations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final pendingList = admin.pendingBankDonations;
    final allDonations = admin.allDonations;

    return Scaffold(
      appBar: AdminAppBar(
        title: 'Donation management',
        subtitle: 'Pending and all donation records',
        showDrawerButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              admin.loadPendingBankDonations();
              admin.loadAllDonations();
            },
          ),
        ],
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminPendingBankDonations),
      body: (admin.loadingBankDonations && admin.loadingAllDonations && pendingList.isEmpty && allDonations.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await admin.loadPendingBankDonations();
                await admin.loadAllDonations();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Pending bank transfers',
                    style: PremiumAppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (pendingList.isEmpty)
                    Text(
                      'No pending bank transfers.',
                      style: PremiumAppTheme.bodyMedium.copyWith(
                        color: PremiumAppTheme.textSecondary,
                      ),
                    )
                  else
                    ...pendingList.map((d) => _buildDonationCard(
                          context: context,
                          admin: admin,
                          donation: d,
                          showActions: true,
                        )),
                  const SizedBox(height: 22),
                  Text(
                    'All donations',
                    style: PremiumAppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (allDonations.isEmpty)
                    Text(
                      'No donations found.',
                      style: PremiumAppTheme.bodyMedium.copyWith(
                        color: PremiumAppTheme.textSecondary,
                      ),
                    )
                  else
                    ...allDonations.map((d) => _buildDonationCard(
                          context: context,
                          admin: admin,
                          donation: d,
                          showActions: false,
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildDonationCard({
    required BuildContext context,
    required AdminProvider admin,
    required Map<String, dynamic> donation,
    required bool showActions,
  }) {
    final rawId = donation['donationId'] ?? donation['donation_id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    final amount = donation['amount']?.toString() ?? '';
    final ref = donation['bankReference'] ?? donation['bank_reference'] ?? '—';
    final donor = donation['donorEmail'] ?? donation['donor_email'] ?? '—';
    final status = (donation['status'] ?? '').toString();
    final paymentMethod = (donation['paymentMethod'] ?? donation['payment_method'] ?? 'unknown').toString();
    final campaign = donation['campaign'];
    final campaignTitle = campaign is Map
        ? (campaign['title']?.toString() ?? 'General Donation')
        : 'General Donation';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Donation #$rawId — $amount',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Campaign: $campaignTitle'),
            Text('Donor: $donor'),
            Text('Payment: $paymentMethod'),
            Text('Status: ${status.toUpperCase()}'),
            if ((paymentMethod == 'bank_transfer') || (ref != '—')) Text('Reference: $ref'),
            if (showActions) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      if (id == 0) return;
                      final r = await admin.confirmBankDonation(id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(r['message']?.toString() ?? '')),
                      );
                    },
                    child: const Text('Confirm'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (id == 0) return;
                      final r = await admin.rejectBankDonation(id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(r['message']?.toString() ?? '')),
                      );
                    },
                    child: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
