import 'package:disaster_response_mobile/features/dashboard/screens/citizen_dashboard_screen.dart';
import 'package:flutter/material.dart';
import '../auth/models/user_model.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/rescue_team_dashboard_screen.dart';
import 'screens/volunteer_dashboard_screen.dart';

class DashboardProvider with ChangeNotifier {
  /// Returns the dashboard widget for the given user based on roleName (and roleId fallback).
  /// Backend role IDs can vary by seed order; roleName is reliable (admin, citizen, volunteer, responder).
  Widget getDashboardForUser(UserModel user) {
    final role = user.roleName?.toLowerCase().trim();
    if (role != null && role.isNotEmpty) {
      switch (role) {
        case 'admin':
          return const AdminDashboardScreen();
        case 'citizen':
          return const CitizenDashboardScreen();
        case 'volunteer':
          return const VolunteerDashboardScreen();
        case 'responder':
        case 'rescue_team':
          return const RescueTeamDashboardScreen();
        default:
          break;
      }
    }
    // Fallback by roleId (backend seed order: admin=1, citizen=2, volunteer=3, responder=4 may vary)
    switch (user.roleId) {
      case 1:
        return const AdminDashboardScreen();
      case 2:
        return const CitizenDashboardScreen();
      case 3:
        return const VolunteerDashboardScreen();
      case 4:
        return const RescueTeamDashboardScreen();
      default:
        return const CitizenDashboardScreen();
    }
  }

  String getDashboardTitleForUser(UserModel user) {
    final role = user.roleName?.toLowerCase().trim();
    if (role != null) {
      switch (role) {
        case 'admin':
          return 'Admin Dashboard';
        case 'citizen':
          return 'Citizen Dashboard';
        case 'volunteer':
          return 'Volunteer Dashboard';
        case 'responder':
        case 'rescue_team':
          return 'Responder Dashboard';
        default:
          break;
      }
    }
    switch (user.roleId) {
      case 1:
        return 'Admin Dashboard';
      case 2:
        return 'Citizen Dashboard';
      case 3:
        return 'Volunteer Dashboard';
      case 4:
        return 'Responder Dashboard';
      default:
        return 'Dashboard';
    }
  }

  String getDashboardTitle(int roleId) {
    switch (roleId) {
      case 1:
        return 'Admin Dashboard';
      case 2:
        return 'Citizen Dashboard';
      case 3:
        return 'Volunteer Dashboard';
      case 4:
        return 'Responder Dashboard';
      default:
        return 'Dashboard';
    }
  }

  Color getPrimaryColor(int roleId) {
    switch (roleId) {
      case 1:
        return Colors.red.shade700;
      case 2:
        return Colors.indigo.shade700;
      case 3:
        return Colors.green.shade700;
      case 4:
        return Colors.blue.shade700;
      default:
        return Colors.indigo.shade700;
    }
  }
}
