import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/dashboard/screens/citizen_dashboard_screen.dart';
import '../../features/dashboard/screens/volunteer_dashboard_screen.dart';
import '../../features/dashboard/screens/rescue_team_dashboard_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/incidents/screens/report_incident_screen.dart';
import '../../features/incidents/screens/incident_list_screen.dart';
import '../../features/incidents/screens/incident_details_screen.dart';
import '../../features/incidents/screens/my_incidents_screen.dart';
import '../../features/incidents/screens/edit_incident_screen.dart';
import '../../features/auth/screens/edit_profile_screen.dart';
import '../../features/admin/screens/incident_management_screen.dart';
import '../../features/admin/screens/volunteer_management_screen.dart';
import '../../features/admin/screens/rescue_team_management_screen.dart';
import '../../features/admin/screens/admin_donation_management_screen.dart';
import '../../features/admin/screens/admin_campaign_management_screen.dart';
import '../../features/admin/screens/pending_mission_requests_screen.dart';
import '../../features/admin/screens/pending_responder_approvals_screen.dart';
import '../../features/notifications/screens/notification_screen.dart';
import '../../features/donations/screens/donate_screen.dart';
import '../../features/dashboard/widgets/map_tab_content.dart';
import '../../features/donations/screens/my_donations_screen.dart';
import '../../features/donations/screens/my_campaign_requests_screen.dart';
import '../../features/missions/screens/mission_details_screen.dart';
import '../../features/missions/models/mission_model.dart';
import '../../features/rescue_team/screens/organization_members_screen.dart';
import '../../features/rescue_team/screens/assigned_incidents_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String reportIncident = '/report-incident';
  static const String incidentDetails = '/incident-details';
  static const String incidentList = '/incident-list';
  static const String myIncidents = '/my-incidents';
  static const String editIncident = '/edit-incident';
  static const String editProfile = '/edit-profile';
  static const String adminIncidents = '/admin/incidents';
  static const String adminVolunteers = '/admin/volunteers';
  static const String adminRescueTeams = '/admin/rescue-teams';
  static const String adminCampaignManagement = '/admin/campaign-management';
  static const String adminPendingBankDonations =
      '/admin/pending-bank-donations';
  static const String adminMissionRequests = '/admin/mission-requests';
  static const String adminResponderApprovals = '/admin/responder-approvals';
  static const String notifications = '/notifications';
  static const String donate = '/donate';
  static const String myDonations = '/my-donations';
  static const String myCampaignRequests = '/my-campaign-requests';
  static const String missionDetails = '/mission-details';
  static const String map = '/map';
  static const String organizationMembers = '/responder/organization-members';
  static const String assignedIncidents = '/responder/assigned-incidents';

  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    dashboard: (context) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        return const LoginScreen();
      }

      switch (user.roleName?.toLowerCase()) {
        case 'admin':
          return const AdminDashboardScreen();
        case 'volunteer':
          return const VolunteerDashboardScreen();
        case 'responder':
        case 'rescue_team':
          return const RescueTeamDashboardScreen();
        default:
          return const CitizenDashboardScreen();
      }
    },
    reportIncident: (context) => const ReportIncidentScreen(),
    incidentDetails: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return IncidentDetailsScreen(incidentId: args?['incidentId']);
    },
    incidentList: (context) => const IncidentListScreen(),
    myIncidents: (context) => const MyIncidentsScreen(),
    editIncident: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return EditIncidentScreen(incidentId: args?['incidentId']);
    },
    editProfile: (context) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      return EditProfileScreen(initialUser: user);
    },
    adminIncidents: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return IncidentManagementScreen(incidentId: args?['incidentId']);
    },
    adminVolunteers: (context) => const VolunteerManagementScreen(),
    adminRescueTeams: (context) => const RescueTeamManagementScreen(),
    adminCampaignManagement: (context) => const AdminCampaignManagementScreen(),
    adminPendingBankDonations: (context) => const AdminDonationManagementScreen(),
    adminMissionRequests: (context) => const PendingMissionRequestsScreen(),
    adminResponderApprovals: (context) => const PendingResponderApprovalsScreen(),
    notifications: (context) => const NotificationScreen(),
    donate: (context) => const DonateScreen(),
    myDonations: (context) => const MyDonationsScreen(),
    myCampaignRequests: (context) => const MyCampaignRequestsScreen(),
    missionDetails: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return MissionDetailsScreen(mission: args?['mission'] as MissionModel);
    },
    map: (context) => const MapTabContent(),
    organizationMembers: (context) => const OrganizationMembersScreen(),
    assignedIncidents: (context) => const AssignedIncidentsScreen(),
  };
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    if (!mounted) return;

    // Navigate based on authentication status
    if (authProvider.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Disaster Response',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Coordinating Rescue Operations',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
