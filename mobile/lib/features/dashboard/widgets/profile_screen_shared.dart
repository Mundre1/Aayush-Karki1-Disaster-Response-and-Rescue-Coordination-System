import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import '../../incidents/incident_provider.dart';
import '../../donations/donation_provider.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';

class ProfileScreenShared extends StatelessWidget {
  const ProfileScreenShared({
    super.key,
    this.extraTiles = const [],
    this.accentColor,
    this.appBarTitle = 'Profile',
  });

  final List<Widget> extraTiles;
  final Color? accentColor;
  final String appBarTitle;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? PremiumAppTheme.primary;
    
    return Consumer3<AuthProvider, IncidentProvider, DonationProvider>(
      builder: (context, authProvider, incidentProvider, donationProvider, _) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: PremiumAppTheme.background,
          body: user == null 
            ? PremiumWidgets.emptyState(
                title: 'No user data',
                message: 'Please log in to view your profile',
                icon: Icons.person_outline,
              )
            : CustomScrollView(
                slivers: [
                  _buildSliverHeader(context, user, color),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsRow(incidentProvider, donationProvider, color),
                          const SizedBox(height: 32),
                          _buildActionSection(
                            context,
                            'Account Information',
                            [
                              _buildDetailTile(Icons.email_outlined, 'Email', user.email, color),
                              _buildDetailTile(Icons.phone_outlined, 'Phone', user.phone ?? 'Not provided', color),
                              _buildDetailTile(Icons.verified_user_outlined, 'Joined', _formatDate(user.createdAt), color),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (extraTiles.isNotEmpty)
                            _buildActionSection(context, 'Activity & Management', extraTiles),
                          const SizedBox(height: 32),
                          _buildLogoutButton(context, authProvider),
                          const SizedBox(height: 40),
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

  Widget _buildSliverHeader(BuildContext context, dynamic user, Color color) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: color,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.darken(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 60,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: color.withValues(alpha: 0.1),
                        child: Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: PremiumAppTheme.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (user.roleName ?? 'User').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
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

  Widget _buildStatsRow(IncidentProvider incidents, DonationProvider donations, Color color) {
    return Row(
      children: [
        _buildStatCard('Reports', incidents.myIncidents.length.toString(), Icons.report_problem_outlined, color),
        const SizedBox(width: 12),
        _buildStatCard('Donations', donations.myDonations.length.toString(), Icons.volunteer_activism_outlined, color),
        const SizedBox(width: 12),
        _buildStatCard('Impact', '8.2', Icons.auto_awesome_outlined, color), // Mocked static impact for now
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: PremiumAppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: PremiumAppTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: PremiumAppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: PremiumAppTheme.labelMedium),
      trailing: Text(value, style: PremiumAppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return PremiumWidgets.premiumButton(
      text: 'Sign Out',
      icon: Icons.logout_rounded,
      backgroundColor: Colors.red.shade50,
      textColor: Colors.red.shade700,
      onPressed: () {
        auth.logout();
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}

