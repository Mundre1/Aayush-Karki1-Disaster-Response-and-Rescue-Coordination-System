import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/incidents/incident_provider.dart';
import '../../features/incidents/screens/incident_list_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/premium_app_bar.dart';
import 'widgets/dashboard_map_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const List<String> _appBarTitles = ['Home', 'Incidents', 'Profile'];

  void _refreshIncidents() {
    final incidentProvider =
        Provider.of<IncidentProvider>(context, listen: false);
    incidentProvider.loadIncidents();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final incidentProvider = Provider.of<IncidentProvider>(context, listen: false);
      incidentProvider.loadIncidents();
      // Also load my incidents/missions if relevant
      incidentProvider.loadMyIncidents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PremiumAppBar(
        title: _appBarTitles[_selectedIndex],
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshIncidents,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          IncidentListScreen(embeddedInDashboard: true),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Incidents'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // Show FAB for citizens to report easily
           if (auth.user?.roleName != 'admin') {
             return FloatingActionButton.extended(
              onPressed: () {
                 Navigator.pushNamed(context, '/report-incident');
              },
              label: const Text('Report'),
              icon: const Icon(Icons.add_alert),
              backgroundColor: Colors.red,
            );
           }
           return const SizedBox.shrink();
        }
      ) : null,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final role = authProvider.user?.roleName?.toLowerCase() ?? 'citizen';

        return Column(
          children: [
            // Interactive Map Section (40% height)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.40,
              child: const DashboardMapWidget(),
            ),

            // Role specific content
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: _buildRoleSpecificContent(context, role),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleSpecificContent(BuildContext context, String role) {
    switch (role) {
      case 'responder':
      case 'rescue_team':
        return const RescueTeamDashboardContent();
      case 'volunteer':
        return const VolunteerDashboardContent();
      case 'admin':
        return const AdminDashboardContent();
      default:
        return const CitizenDashboardContent();
    }
  }
}

class CitizenDashboardContent extends StatelessWidget {
  const CitizenDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: 20),
          const Text(
            'Your Recent Reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Consumer<IncidentProvider>(
            builder: (context, provider, child) {
              final myIncidents = provider.myIncidents;
              if (myIncidents.isEmpty) {
                 return AppEmptyState(
                  title: 'No reports yet',
                  message: 'Incidents you report will appear here.',
                  icon: Icons.history,
                );
              }
              return Column(
                children: myIncidents.take(3).map((i) => _buildCompactIncidentCard(context, i)).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildDonateCard(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
             Icon(Icons.shield_outlined, size: 40, color: Colors.blue[700]),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: const [
                   Text('Stay Safe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   Text('Check the map for incidents near you.'),
                 ],
               ),
             )
          ],
        ),
      ),
    );
  }
}

class RescueTeamDashboardContent extends StatelessWidget {
  const RescueTeamDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mission Control',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
           Consumer<IncidentProvider>(
            builder: (context, provider, child) {
              // In a real app, we'd filter by 'assigned to my team'
              // For now, let's show 'assigned' status incidents
              final assignedIncidents = provider.incidents.where((i) => i.status == 'assigned' || i.status == 'in_progress').toList();

              if (assignedIncidents.isEmpty) {
                 return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No active missions.")));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${assignedIncidents.length} Active Missions', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  ...assignedIncidents.map((i) => _buildCompactIncidentCard(context, i)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class VolunteerDashboardContent extends StatelessWidget {
  const VolunteerDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Volunteer Opportunities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
           Consumer<IncidentProvider>(
            builder: (context, provider, child) {
              // Show pending incidents as opportunities
              final opportunities = provider.incidents.where((i) => i.status == 'pending').toList();

              return Column(
                children: opportunities.take(5).map((i) => _buildCompactIncidentCard(context, i)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Reusing the stats grid from original code
           Consumer<IncidentProvider>(
            builder: (context, incidentProvider, child) {
               final stats = {
                'total': incidentProvider.incidents.length,
                'pending': incidentProvider.incidents.where((i) => i.status == 'pending').length,
                'assigned': incidentProvider.incidents.where((i) => i.status == 'assigned').length,
                'resolved': incidentProvider.incidents.where((i) => i.status == 'resolved').length,
              };
               return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard('Total', stats['total'].toString(), Icons.folder, Colors.grey),
                  _buildStatCard('Pending', stats['pending'].toString(), Icons.warning, Colors.orange),
                  _buildStatCard('Assigned', stats['assigned'].toString(), Icons.run_circle, Colors.blue),
                  _buildStatCard('Resolved', stats['resolved'].toString(), Icons.check, Colors.green),
                ],
              );
            }
           )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title),
        ],
      ),
    );
  }
}


Widget _buildCompactIncidentCard(BuildContext context, dynamic incident) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
             color: _getStatusColor(incident.status).withValues(alpha: 0.1),
             shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning_amber, color: _getStatusColor(incident.status)),
        ),
        title: Text(incident.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(incident.location?.address ?? 'Unknown Location', maxLines: 1),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, '/incident-details', arguments: {'incidentId': incident.incidentId}),
      ),
    );
}

Widget _buildDonateCard(BuildContext context) {
   return AppCard(
    child: InkWell(
      onTap: () => Navigator.pushNamed(context, '/donate'),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.pink),
            const SizedBox(width: 12),
            const Expanded(child: Text('Support Disaster Relief', style: TextStyle(fontWeight: FontWeight.bold))),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    ),
  );
}

Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'in_progress': return Colors.purple;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static String _displayRole(String? role) {
    if (role == null || role.isEmpty) return 'User';
    if (role.length == 1) return role.toUpperCase();
    return '${role[0].toUpperCase()}${role.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (user == null) {
          return Center(
            child: Text(
              'No user data available',
              style: PremiumAppTheme.bodyLarge.copyWith(
                color: PremiumAppTheme.textSecondary,
              ),
            ),
          );
        }

        final name = user.name.trim();
        final initial = name.isEmpty
            ? '?'
            : name.substring(0, 1).toUpperCase();
        final roleLabel = _displayRole(user.roleName);

        return ColoredBox(
          color: PremiumAppTheme.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                PremiumAppTheme.primary.withValues(alpha: 0.07),
                                PremiumAppTheme.primaryLight.withValues(
                                  alpha: 0.14,
                                ),
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: PremiumAppTheme.surface,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: PremiumAppTheme.primary
                                          .withValues(alpha: 0.18),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: PremiumAppTheme.surface,
                                  child: CircleAvatar(
                                    radius: 42,
                                    backgroundColor: PremiumAppTheme.primaryLight
                                        .withValues(alpha: 0.22),
                                    child: Text(
                                      initial,
                                      style: PremiumAppTheme.headlineMedium
                                          .copyWith(
                                        color: PremiumAppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                name.isEmpty ? 'User' : name,
                                textAlign: TextAlign.center,
                                style: PremiumAppTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user.email,
                                textAlign: TextAlign.center,
                                style: PremiumAppTheme.bodyMedium.copyWith(
                                  color: PremiumAppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: PremiumAppTheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: PremiumAppTheme.labelLarge.copyWith(
                                    color: PremiumAppTheme.primary,
                                    fontWeight: FontWeight.w600,
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
                const SizedBox(height: 14),
                AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: PremiumAppTheme.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Details from your registration',
                        style: PremiumAppTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      _ProfileDetailTile(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: user.email,
                      ),
                      Divider(
                        height: 24,
                        thickness: 1,
                        color: PremiumAppTheme.border,
                      ),
                      _ProfileDetailTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: user.phone ?? 'Not provided',
                      ),
                      Divider(
                        height: 24,
                        thickness: 1,
                        color: PremiumAppTheme.border,
                      ),
                      _ProfileDetailTile(
                        icon: Icons.badge_outlined,
                        label: 'Role',
                        value: roleLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shortcuts',
                        style: PremiumAppTheme.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quick links to your activity',
                        style: PremiumAppTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/my-donations',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: PremiumAppTheme.emergency
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.volunteer_activism_rounded,
                                    color: PremiumAppTheme.emergency,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'My donations',
                                        style: PremiumAppTheme.titleMedium
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'History and receipt details',
                                        style: PremiumAppTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: PremiumAppTheme.textDisabled,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileDetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: PremiumAppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: PremiumAppTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: PremiumAppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

