import 'package:disaster_response_mobile/features/dashboard/weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_config.dart';
import 'features/auth/auth_provider.dart';
import 'features/incidents/incident_provider.dart';
import 'features/dashboard/dashboard_provider.dart';
import 'features/admin/admin_provider.dart';
import 'features/volunteers/volunteer_provider.dart';
import 'features/rescue_team/rescue_team_provider.dart';
import 'features/notifications/notification_provider.dart';
import 'features/donations/donation_provider.dart';
import 'features/donations/campaign_provider.dart';
import 'features/comments/comment_provider.dart';
import 'core/services/connectivity_service.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open Hive Boxes
  await Hive.openBox(AppConfig.incidentsBox);
  await Hive.openBox(AppConfig.syncQueueBox);
  await Hive.openBox(AppConfig.userProfileBox);
  await Hive.openBox(AppConfig.missionsBox);
  await Hive.openBox(AppConfig.notificationsBox);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => VolunteerProvider()),
        ChangeNotifierProvider(create: (_) => RescueTeamProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DonationProvider()),
        ChangeNotifierProvider(create: (_) => CampaignProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: ChangeNotifierProvider(
        create: (_) => DashboardProvider(),
        child: MaterialApp(
          title: 'Disaster Response',
          debugShowCheckedModeBanner: false,
          theme: PremiumAppTheme.lightTheme,
          darkTheme: PremiumAppTheme.lightTheme, // For now, same theme
          themeMode: ThemeMode.light,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
        ),
      ),
    );
  }
}
