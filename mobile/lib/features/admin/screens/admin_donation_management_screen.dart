import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../admin_provider.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/widgets/admin_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/premium_widgets.dart';

class AdminDonationManagementScreen extends StatefulWidget {
  const AdminDonationManagementScreen({super.key});

  @override
  State<AdminDonationManagementScreen> createState() =>
      _AdminDonationManagementScreenState();
}

class _AdminDonationManagementScreenState
    extends State<AdminDonationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Map<String, dynamic> _asStringKeyedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  void _showDonationDetails(Map<String, dynamic> d) {
    final id = d['donationId'] ?? d['id'];
    final amount = d['amount']?.toString() ?? '0';
    final donorName =
        d['donorName'] ?? d['donor_name'] ?? d['donorEmail'] ?? d['donor_email'] ?? 'Anonymous';
    final donorEmail = d['donorEmail'] ?? d['donor_email'] ?? '-';
    final method = (d['paymentMethod'] ?? d['payment_method'] ?? 'unknown').toString();
    final status = (d['status'] ?? 'pending').toString().toLowerCase();
    final txId = d['transactionId'] ?? d['transaction_id'] ?? '-';
    final ref = d['bankReference'] ?? d['bank_reference'] ?? '-';
    final createdAt = DateTime.tryParse((d['createdAt'] ?? d['created_at'] ?? '').toString());
    final campaign = d['campaign'];
    final campaignTitle =
        campaign is Map ? (campaign['title'] ?? 'General Donation') : 'General Donation';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donation Details', style: PremiumAppTheme.titleLarge),
            const SizedBox(height: 12),
            Text('ID: #$id'),
            Text('Amount: Rs. ${NumberFormat('#,###').format(double.tryParse(amount) ?? 0)}'),
            Text('Donor: $donorName'),
            Text('Donor Email: $donorEmail'),
            Text('Campaign: $campaignTitle'),
            Text('Method: $method'),
            Text('Status: ${status.toUpperCase()}'),
            Text('Transaction ID: $txId'),
            Text('Bank Reference: $ref'),
            if (createdAt != null)
              Text('Date: ${DateFormat('MMM dd, yyyy hh:mm a').format(createdAt)}'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                method == 'bank_transfer'
                    ? 'Bank transfer pending donations can be manually approved/rejected by admin.'
                    : 'Gateway donations are usually confirmed automatically after payment verification.',
                style: PremiumAppTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    final admin = context.read<AdminProvider>();
    await Future.wait([
      admin.loadPendingBankDonations(),
      admin.loadAllDonations(),
      admin.loadDashboardStats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = _asStringKeyedMap(admin.dashboardStats?['donations']);
    
    // Filtering logic
    List<Map<String, dynamic>> filteredList(List<Map<String, dynamic>> list, String? status) {
      Iterable<Map<String, dynamic>> items = list;
      if (status != null) {
        items = items.where((d) => d['status']?.toString().toLowerCase() == status.toLowerCase());
      }
      if (_searchQuery.isNotEmpty) {
        items = items.where((d) {
          final donor = (d['donorEmail'] ?? d['donor_email'] ?? '').toString().toLowerCase();
          final transId = (d['transactionId'] ?? d['transaction_id'] ?? '').toString().toLowerCase();
          final ref = (d['bankReference'] ?? d['bank_reference'] ?? '').toString().toLowerCase();
          return donor.contains(_searchQuery.toLowerCase()) || 
                 transId.contains(_searchQuery.toLowerCase()) ||
                 ref.contains(_searchQuery.toLowerCase());
        });
      }
      return items.toList();
    }

    return Scaffold(
      backgroundColor: PremiumAppTheme.background,
      appBar: AdminAppBar(
        title: 'Donation Management',
        showDrawerButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
          ),
        ],
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminPendingBankDonations),
      body: Column(
        children: [
          // Premium Header with Stats
          Container(
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
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildStatsGrid(stats),
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
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.white,
              unselectedLabelColor: PremiumAppTheme.textSecondary,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: PremiumAppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'All Activity'),
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDonationList(filteredList(admin.allDonations, null), admin),
                _buildDonationList(filteredList(admin.allDonations, 'pending'), admin),
                _buildDonationList(filteredList(admin.allDonations, 'completed'), admin),
                _buildDonationList(filteredList(admin.allDonations, 'rejected'), admin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final totalRaised = stats['totalAmount'] ?? 0.0;
    final totalCount = stats['totalCount'] ?? 0;
    final pendingCount = stats['pendingCount'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: PremiumWidgets.statCard(
            label: 'Total Raised',
            value: 'Rs. ${NumberFormat('#,###').format(totalRaised)}',
            icon: Icons.account_balance_wallet_rounded,
            color: PremiumAppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumWidgets.statCard(
            label: 'Total Gifts',
            value: totalCount.toString(),
            icon: Icons.volunteer_activism_rounded,
            color: PremiumAppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumWidgets.statCard(
            label: 'Pending',
            value: pendingCount.toString(),
            icon: Icons.pending_actions_rounded,
            color: PremiumAppTheme.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search donors or references...',
        prefixIcon: const Icon(Icons.search_rounded, color: PremiumAppTheme.primary),
        fillColor: PremiumAppTheme.background,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: PremiumAppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
    );
  }

  Widget _buildDonationList(List<Map<String, dynamic>> donations, AdminProvider admin) {
    if (admin.loadingAllDonations) {
      return PremiumWidgets.loadingIndicator(message: 'Syncing donation records...');
    }
    if (donations.isEmpty) {
      return PremiumWidgets.emptyState(
        title: 'No Donations Found',
        message: _searchQuery.isNotEmpty 
            ? 'No records match your search criteria.'
            : 'No donations have been recorded in this category.',
        icon: Icons.history_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: donations.length,
        itemBuilder: (context, index) {
          final d = donations[index];
          return _buildDonationCard(d, admin);
        },
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> d, AdminProvider admin) {
    final id = d['donationId'] ?? d['id'];
    final amount = d['amount']?.toString() ?? '0';
    final donor = d['donorName'] ?? d['donor_name'] ?? d['donorEmail'] ?? d['donor_email'] ?? 'Anonymous Donor';
    final status = (d['status'] ?? 'pending').toString().toLowerCase();
    final method = (d['paymentMethod'] ?? d['payment_method'] ?? 'unknown').toString();
    final date = DateTime.tryParse(d['createdAt'] ?? '') ?? DateTime.now();
    final campaign = d['campaign'];
    final campaignTitle = campaign is Map ? (campaign['title'] ?? 'General Fund') : 'General Fund';
    final ref = d['bankReference'] ?? d['bank_reference'];

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDonationDetails(d),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: PremiumAppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$id',
                            style: PremiumAppTheme.labelSmall.copyWith(
                              color: PremiumAppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        PremiumWidgets.statusIndicator(
                          status: status == 'completed' ? 'resolved' : (status == 'rejected' ? 'closed' : 'pending'),
                          text: status,
                          size: 8,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PremiumAppTheme.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            method == 'bank_transfer' ? Icons.account_balance_rounded : Icons.credit_card_rounded,
                            color: PremiumAppTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rs. ${NumberFormat('#,###').format(double.tryParse(amount) ?? 0)}',
                                style: PremiumAppTheme.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: PremiumAppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                donor,
                                style: PremiumAppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                campaignTitle,
                                style: PremiumAppTheme.bodySmall.copyWith(color: PremiumAppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('MMM dd').format(date),
                              style: PremiumAppTheme.labelMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('hh:mm a').format(date),
                              style: PremiumAppTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (ref != null && ref.toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: PremiumAppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: PremiumAppTheme.border, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tag_rounded, size: 14, color: PremiumAppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'REF: $ref',
                              style: PremiumAppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (status == 'pending' && method == 'bank_transfer')
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
                          onPressed: () => _confirmDonation(id),
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('Verify Payment'),
                          style: TextButton.styleFrom(
                            foregroundColor: PremiumAppTheme.success,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 24, color: PremiumAppTheme.border),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _rejectDonation(id),
                          icon: const Icon(Icons.cancel_rounded, size: 18),
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
        ),
      ),
    );
  }

  Future<void> _confirmDonation(dynamic id) async {
    final donationId = id is int ? id : int.tryParse(id.toString()) ?? 0;
    if (donationId == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Donation'),
        content: const Text('Are you sure you want to verify this bank transfer? This action will update the campaign balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          PremiumWidgets.premiumButton(
            text: 'Confirm',
            onPressed: () => Navigator.pop(context, true),
            width: 120,
            height: 44,
            backgroundColor: PremiumAppTheme.success,
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final admin = context.read<AdminProvider>();
      final result = await admin.confirmBankDonation(donationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Donation confirmed successfully'),
            backgroundColor: result['success'] ? PremiumAppTheme.success : PremiumAppTheme.emergency,
          ),
        );
        _refreshData();
      }
    }
  }

  Future<void> _rejectDonation(dynamic id) async {
    final donationId = id is int ? id : int.tryParse(id.toString()) ?? 0;
    if (donationId == 0) return;

    final rejected = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Donation'),
        content: const Text('Are you sure you want to reject this bank transfer? The donor will be notified of the rejection.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          PremiumWidgets.premiumButton(
            text: 'Reject',
            onPressed: () => Navigator.pop(context, true),
            width: 120,
            height: 44,
            backgroundColor: PremiumAppTheme.emergency,
          ),
        ],
      ),
    );

    if (rejected == true && mounted) {
      final admin = context.read<AdminProvider>();
      final result = await admin.rejectBankDonation(donationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Donation rejected'),
            backgroundColor: result['success'] ? PremiumAppTheme.success : PremiumAppTheme.emergency,
          ),
        );
        _refreshData();
      }
    }
  }
}

