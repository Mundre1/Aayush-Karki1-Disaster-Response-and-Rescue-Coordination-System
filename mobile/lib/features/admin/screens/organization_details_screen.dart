import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/admin_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';

class OrganizationDetailsScreen extends StatefulWidget {
  final int organizationId;

  const OrganizationDetailsScreen({super.key, required this.organizationId});

  @override
  State<OrganizationDetailsScreen> createState() =>
      _OrganizationDetailsScreenState();
}

class _OrganizationDetailsScreenState extends State<OrganizationDetailsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _organization = <String, dynamic>{};
  List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _missions = <Map<String, dynamic>>[];

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw.map(_asMap).toList();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await context
        .read<AdminProvider>()
        .getOrganizationDetails(widget.organizationId);
    if (!mounted) return;

    if (result['success'] == true) {
      final organization = _asMap(result['organization']);
      setState(() {
        _organization = organization;
        _members = _asMapList(organization['members']);
        _missions = _asMapList(organization['missions']);
        _loading = false;
      });
      return;
    }

    setState(() {
      _error = result['message']?.toString() ?? 'Failed to load details';
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orgName = _organization['organizationName']?.toString() ?? 'Organization';
    final orgType = _organization['specialization']?.toString() ?? 'Responder Team';
    final isActive = _organization['isActive'] == true;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: PremiumAppTheme.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: PremiumWidgets.profileHeader(
                  title: orgName,
                  subtitle: orgType,
                  avatar: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  stats: [
                    _buildHeaderStat('Members', _members.length.toString()),
                    _buildHeaderStat('Missions', _missions.length.toString()),
                    _buildHeaderStat(
                      'Status',
                      isActive ? 'Active' : 'Inactive',
                      isStatus: true,
                    ),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  Material(
                    color: PremiumAppTheme.surface,
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                    child: TabBar(
                      labelColor: PremiumAppTheme.primary,
                      unselectedLabelColor: PremiumAppTheme.textSecondary,
                      indicatorColor: PremiumAppTheme.primary,
                      indicatorWeight: 3,
                      labelStyle: PremiumAppTheme.labelLarge.copyWith(fontWeight: FontWeight.w700),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Team Members'),
                        Tab(text: 'Mission History'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: _loading
              ? PremiumWidgets.loadingIndicator(message: 'Retrieving details...')
              : _error != null
              ? PremiumWidgets.emptyState(
                  title: 'Load Error',
                  message: _error!,
                  icon: Icons.error_outline_rounded,
                  buttonText: 'Retry',
                  onAction: _loadData,
                )
              : TabBarView(
                  children: [
                    _buildOverviewTab(),
                    _buildMembersTab(),
                    _buildIncidentsTab(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, {bool isStatus = false}) {
    return Column(
      children: [
        Text(
          value,
          style: PremiumAppTheme.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: PremiumAppTheme.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PremiumWidgets.sectionHeader(title: 'Organization Info'),
          Row(
            children: [
              Expanded(
                child: PremiumWidgets.statCard(
                  label: 'Contact Person',
                  value: _organization['contact']?.toString() ?? 'N/A',
                  icon: Icons.person_outline_rounded,
                  color: PremiumAppTheme.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PremiumWidgets.statCard(
                  label: 'Experience',
                  value: '4+ Years', // Placeholder or add to DB later
                  icon: Icons.workspace_premium_outlined,
                  color: PremiumAppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PremiumWidgets.premiumCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detailed Description', style: PremiumAppTheme.titleMedium),
                const SizedBox(height: 12),
                Text(
                  _organization['description']?.toString() ?? 
                  'No detailed description provided for this organization.',
                  style: PremiumAppTheme.bodyMedium.copyWith(
                    color: PremiumAppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                _infoRowItem(Icons.location_on_rounded, 'Operational Base', 'Kathmandu, Nepal'),
                _infoRowItem(Icons.verified_user_rounded, 'Certification', 'Certified Responder'),
                _infoRowItem(Icons.calendar_today_rounded, 'Joined System', 'January 2024'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: PremiumAppTheme.primaryLight),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: PremiumAppTheme.bodyMedium.copyWith(color: PremiumAppTheme.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: PremiumAppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return PremiumWidgets.emptyState(
        title: 'No Team Members',
        message: 'This organization has not registered any responders yet.',
        icon: Icons.people_outline_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final status = member['responderStatus']?.toString() ?? 'pending';
          final name = member['name']?.toString() ?? 'Responder';
          final email = member['email']?.toString() ?? '';

          return PremiumWidgets.modernListItem(
            title: name,
            subtitle: email,
            leading: CircleAvatar(
              backgroundColor: PremiumAppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(color: PremiumAppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            trailing: PremiumWidgets.statusIndicator(
              status: status,
              text: status,
              size: 8,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIncidentsTab() {
    if (_missions.isEmpty) {
      return PremiumWidgets.emptyState(
        title: 'Clean Mission Log',
        message: 'No active or historical missions found for this team.',
        icon: Icons.assignment_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _missions.length,
        itemBuilder: (context, index) {
          final mission = _missions[index];
          final incident = _asMap(mission['incident']);
          final missionStatus = (mission['missionStatus'] ?? 'assigned').toString();
          
          return PremiumWidgets.modernListItem(
            title: incident['title']?.toString() ?? 'Mission Assignment',
            subtitle: 'Status: ${missionStatus.toUpperCase()}',
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PremiumAppTheme.emergency.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flash_on_rounded, color: PremiumAppTheme.emergency, size: 24),
            ),
            onTap: () {
              // Navigate to mission details if needed
            },
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final Material _tabBar;

  @override
  double get minExtent => 48; // Standard TabBar height
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _tabBar;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

