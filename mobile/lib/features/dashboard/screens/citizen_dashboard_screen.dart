import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../incidents/incident_provider.dart';
import '../../notifications/notification_provider.dart';
import '../../notifications/widgets/notification_badge.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../widgets/profile_screen_shared.dart';
import '../../../core/widgets/connectivity_banner.dart';
import '../../auth/auth_provider.dart';
import '../../donations/screens/donate_screen.dart';
import '../../donations/donation_provider.dart';
import '../weather_provider.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<IncidentProvider>(context, listen: false).loadIncidents();
      Provider.of<IncidentProvider>(context, listen: false).loadMyIncidents();
      Provider.of<DonationProvider>(context, listen: false).loadMyDonations();
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).updateUnreadCount();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeScreen(
                  onSwitchToTab: (index) =>
                      setState(() => _selectedIndex = index),
                ),
                const IncidentsScreen(),
                const DonateScreen(),
                ProfileScreenShared(
                  extraTiles: [
                    ListTile(
                      leading: Icon(
                        Icons.report_problem,
                        color: PremiumAppTheme.primary,
                      ),
                      title: const Text('My Incidents'),
                      subtitle: const Text(
                        'View and manage your reported incidents',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.myIncidents);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPremiumBottomNav(),
    );
  }

  Widget _buildPremiumBottomNav() {
    return Container(
      height: 90,
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                _buildNavItem(Icons.warning_amber_rounded, 'Hazards', 1),
                _buildEmergencyButton(),
                _buildNavItem(Icons.volunteer_activism_rounded, 'Donate', 2),
                _buildNavItem(Icons.person_rounded, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? PremiumAppTheme.primary
        : PremiumAppTheme.textDisabled;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.transparent, // Increase tap area
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: PremiumAppTheme.labelSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),

              height: 4,
              width: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: PremiumAppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.pushNamed(context, AppRoutes.reportIncident);
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PremiumAppTheme.emergency.withValues(alpha: 
                    0.25 * (2 - _pulseAnimation.value),
                  ),
                  blurRadius: 15 * _pulseAnimation.value,
                  spreadRadius: 2 * _pulseAnimation.value,
                ),
              ],
            ),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PremiumAppTheme.emergency,
                    PremiumAppTheme.emergency.darken(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sos_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSwitchToTab});
  final void Function(int index)? onSwitchToTab;

  Future<void> _callEmergency(String number) async {
    try {
      final Uri url = Uri.parse('tel:$number');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching dialer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<IncidentProvider, AuthProvider>(
      builder: (context, incidentProvider, authProvider, child) {
        final user = authProvider.user;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, user),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherContextCard(),
                    const SizedBox(height: 28),
                    _buildAlertBanner(),
                    const SizedBox(height: 28),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    _buildHazardMapTeaser(context),
                    const SizedBox(height: 32),
                    _buildStatsGrid(incidentProvider),
                    const SizedBox(height: 32),
                    _buildSafetyTipsCarousel(),
                    const SizedBox(height: 32),
                    if (incidentProvider.myIncidents.isNotEmpty) ...[
                      _buildSectionHeader('Your Recent Reports', () {}),
                      const SizedBox(height: 16),
                      ...incidentProvider.myIncidents
                          .take(2)
                          .map(
                            (incident) =>
                                _buildCompactIncidentCard(context, incident),
                          ),
                      const SizedBox(height: 16),
                    ],
                    _buildSectionHeader(
                      'Nearby Incidents',
                      () => onSwitchToTab?.call(1),
                    ),
                    const SizedBox(height: 16),
                    if (incidentProvider.incidents.isEmpty)
                      PremiumWidgets.emptyState(
                        title: 'All Clear',
                        message:
                            'No incidents reported in your area. Stay safe!',
                        icon: Icons.check_circle_outline,
                      )
                    else
                      ...incidentProvider.incidents
                          .take(3)
                          .map(
                            (incident) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: PremiumWidgets.incidentCard(
                                title: incident.title,
                                description: incident.description,
                                location:
                                    incident.location?.address ??
                                    'Detecting location...',
                                status: incident.status,
                                severity: incident.severity,
                                reportedAt: incident.reportedAt,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.incidentDetails,
                                    arguments: {
                                      'incidentId': incident.incidentId,
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherContextCard() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) {
        if (weatherProvider.isLoading) {
          return Container(
            height: 160,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (weatherProvider.error != null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PremiumAppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: PremiumAppTheme.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: PremiumAppTheme.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Weather unavailable: ${weatherProvider.error}',
                    style: PremiumAppTheme.bodySmall.copyWith(
                      color: PremiumAppTheme.warning,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => weatherProvider.fetchWeather(),
                ),
              ],
            ),
          );
        }

        final weather = weatherProvider.currentWeather;
        if (weather == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getWeatherIcon(weather.condition),
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${weather.condition} • ${weather.city}',
                            style: PremiumAppTheme.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: PremiumAppTheme.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${weather.riskLevel} Risk',
                          style: PremiumAppTheme.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _weatherInfoItem(
                    Icons.water_drop_outlined,
                    '${weather.humidity}%',
                    'Humidity',
                  ),
                  _weatherInfoItem(
                    Icons.air,
                    '${weather.windSpeed}km/h',
                    'Wind',
                  ),
                  _weatherInfoItem(Icons.refresh, 'Live', 'Status'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case 'Clear':
        return Icons.wb_sunny_rounded;
      case 'Partly Cloudy':
        return Icons.cloud_queue_rounded;
      case 'Foggy':
        return Icons.blur_on_rounded;
      case 'Rainy':
      case 'Rain Showers':
      case 'Drizzle':
        return Icons.umbrella_rounded;
      case 'Thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'Snowy':
        return Icons.ac_unit_rounded;
      default:
        return Icons.cloud_rounded;
    }
  }

  Widget _weatherInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, dynamic user) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      stretch: true,
      backgroundColor: PremiumAppTheme.primary,
      actions: [
        IconButton(
          icon: const Icon(Icons.assignment_rounded, color: Colors.white),
          tooltip: 'My Reports',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.myIncidents),
        ),
        IconButton(
          icon: const Icon(Icons.map_rounded, color: Colors.white),
          tooltip: 'Hazard Map',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.map),
        ),
        const NotificationBadge(),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PremiumAppTheme.primary,
                    PremiumAppTheme.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Icon(
                Icons.shield_rounded,
                size: 200,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: Protected',
                            style: PremiumAppTheme.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            user?.name ?? 'Guest User',
                            style: PremiumAppTheme.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
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

  Widget _buildAlertBanner() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) {
        final weather = weatherProvider.currentWeather;
        if (weather == null || weather.alertTitle == 'All Clear') {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PremiumAppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PremiumAppTheme.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PremiumAppTheme.warning,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: PremiumAppTheme.warning.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notification_important,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.alertTitle,
                      style: PremiumAppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weather.alertDescription,
                      style: PremiumAppTheme.bodySmall.copyWith(
                        color: PremiumAppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: PremiumAppTheme.warning),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.local_hospital,
        'label': 'Ambulance',
        'color': Colors.red,
        'number': '102',
      },
      {
        'icon': Icons.local_fire_department,
        'label': 'Fire Dept',
        'color': Colors.orange,
        'number': '101',
      },
      {
        'icon': Icons.local_police,
        'label': 'Police',
        'color': Colors.blue,
        'number': '100',
      },
      {
        'icon': Icons.volunteer_activism,
        'label': 'Help',
        'color': Colors.purple,
        'action': () => _showHelpDialog(context),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Assistance',
          style: PremiumAppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions
              .map(
                (a) => _buildActionItem(
                  icon: a['icon'] as IconData,
                  label: a['label'] as String,
                  color: a['color'] as Color,
                  onTap: a['number'] != null
                      ? () => _callEmergency(a['number'] as String)
                      : (a['action'] as VoidCallback),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Emergency Help'),
        content: const Text(
          'If you need immediate assistance but are unsure who to call, please use the general emergency number (100) or report an incident using the FAB button below.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _callEmergency('100');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumAppTheme.emergency,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Call Police (100)'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: PremiumAppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: PremiumAppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardMapTeaser(BuildContext context) {
    return PremiumWidgets.premiumCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.pushNamed(context, AppRoutes.map),
      child: Stack(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade100, Colors.grey.shade200],
              ),
            ),
            child: Opacity(
              opacity: 0.4,
              child: Icon(
                Icons.map,
                size: 100,
                color: PremiumAppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Hazard Map',
                      style: PremiumAppTheme.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'View real-time threats nearby',
                      style: PremiumAppTheme.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: PremiumAppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Open Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTipsCarousel() {
    final tips = [
      {
        'title': 'Earthquake Safety',
        'desc':
            'Drop, Cover, and Hold on during shaking. Stay clear of windows.',
        'icon': Icons.emergency_share,
        'color': Colors.brown,
        'steps': [
          'Drop to your hands and knees immediately.',
          'Cover your head and neck with your arms.',
          'Hold on to your shelter until shaking stops.',
          'Stay away from glass, windows, and heavy furniture.',
          'If outside, move to an open area away from buildings.',
        ],
      },
      {
        'title': 'Flood Protocols',
        'desc':
            'Move to higher ground. Avoid walking or driving through water.',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'steps': [
          'Move to the highest level of the building if trapped.',
          'Do not walk, swim, or drive through flood waters.',
          'Stay off bridges over fast-moving water.',
          'Disconnect electrical appliances if safe to do so.',
          'Listen to emergency channels for evacuation orders.',
        ],
      },
      {
        'title': 'Fire Response',
        'desc': 'Stay low, crawl under smoke. Identify all exit routes.',
        'icon': Icons.local_fire_department,
        'color': Colors.red,
        'steps': [
          'Stay low to the ground to avoid smoke inhalation.',
          'Check doors for heat with the back of your hand.',
          'If your clothes catch fire: Stop, Drop, and Roll.',
          'Never use elevators during a fire.',
          'Have a designated meeting place outside.',
        ],
      },
      {
        'title': 'Landslide Alert',
        'desc': 'Listen for rumbling. Look for tilted trees or ground cracks.',
        'icon': Icons.landscape,
        'color': Colors.orange,
        'steps': [
          'Listen for unusual sounds like trees cracking.',
          'Watch for new cracks or bulges in the ground.',
          'Evacuate immediately if you suspect a landslide.',
          'Stay alert while driving; look for collapsed pavement.',
          'If trapped, curl into a tight ball and protect your head.',
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Safety Recommendations',
              style: PremiumAppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {}, // Could link to a full library later
              child: Text(
                'View Info',
                style: TextStyle(color: PremiumAppTheme.primary, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.only(right: 20),
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final tip = tips[index];
              final color = tip['color'] as Color;
              return InkWell(
                onTap: () => _showSafetyGuideline(
                  context,
                  tip['title'] as String,
                  tip['steps'] as List<String>,
                  color,
                  tip['icon'] as IconData,
                ),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          tip['icon'] as IconData,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip['title'] as String,
                              style: PremiumAppTheme.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.darken(0.2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tip['desc'] as String,
                              style: PremiumAppTheme.bodySmall.copyWith(
                                color: PremiumAppTheme.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSafetyGuideline(
    BuildContext context,
    String title,
    List<String> steps,
    Color color,
    IconData icon,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: PremiumAppTheme.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Emergency Protocols & Tips',
                          style: PremiumAppTheme.bodySmall.copyWith(
                            color: PremiumAppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: steps.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          steps[index],
                          style: PremiumAppTheme.bodyMedium.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'I Understand, Stay Safe',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(IncidentProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            'Active Hazards',
            provider.incidents.length.toString(),
            Icons.nature_people,
            PremiumAppTheme.emergency,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatTile(
            'Teams Deployed',
            provider.incidents
                .where((i) => i.status == 'assigned')
                .length
                .toString(),
            Icons.engineering,
            PremiumAppTheme.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PremiumAppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PremiumAppTheme.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: PremiumAppTheme.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: PremiumAppTheme.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: PremiumAppTheme.labelSmall.copyWith(
              color: PremiumAppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: PremiumAppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: PremiumAppTheme.primary),
          child: const Row(
            children: [
              Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactIncidentCard(BuildContext context, dynamic incident) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumWidgets.premiumCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.incidentDetails,
            arguments: {'incidentId': incident.incidentId},
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PremiumAppTheme.getSeverityColor(
                  incident.severity,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: PremiumAppTheme.getSeverityColor(incident.severity),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    style: PremiumAppTheme.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PremiumAppTheme.getStatusColor(
                            incident.status,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        incident.status.toUpperCase(),
                        style: PremiumAppTheme.labelSmall.copyWith(
                          color: PremiumAppTheme.getStatusColor(
                            incident.status,
                          ),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: PremiumAppBar(
            title: 'Incidents',
            actions: [
              const NotificationBadge(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadIncidents(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => provider.loadIncidents(),
            child: provider.isLoading
                ? PremiumWidgets.loadingIndicator(
                    message: 'Loading incidents...',
                  )
                : provider.errorMessage != null
                ? PremiumWidgets.emptyState(
                    title: 'Error loading incidents',
                    message: provider.errorMessage!,
                    icon: Icons.error_outline,
                    buttonText: 'Retry',
                    onAction: () => provider.loadIncidents(),
                  )
                : provider.incidents.isEmpty &&
                      provider.pendingIncidents.isEmpty
                ? PremiumWidgets.emptyState(
                    title: 'No incidents reported',
                    message: 'Be the first to report an incident in your area',
                    icon: Icons.warning_amber_outlined,
                    buttonText: 'Report Incident',
                    onAction: () {
                      Navigator.pushNamed(context, AppRoutes.reportIncident);
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (provider.pendingIncidents.isNotEmpty) ...[
                        Text(
                          'Pending Sync (${provider.pendingIncidents.length})',
                          style: PremiumAppTheme.labelMedium.copyWith(
                            color: PremiumAppTheme.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...provider.pendingIncidents.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Opacity(
                              opacity: 0.7,
                              child: PremiumWidgets.incidentCard(
                                title: item.data['title'] ?? 'New Incident',
                                description: item.data['description'] ?? '',
                                location:
                                    item.data['address'] ?? 'Detecting...',
                                status: 'Pending Sync',
                                severity: item.data['severity'] ?? 'low',
                                reportedAt: item.createdAt,
                                onTap: null,
                              ),
                            ),
                          );
                        }),
                        const Divider(),
                        const SizedBox(height: 8),
                      ],
                      ...provider.incidents.map((incident) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: PremiumWidgets.incidentCard(
                            title: incident.title,
                            description: incident.description,
                            location:
                                incident.location?.address ??
                                'Unknown location',
                            status: incident.status,
                            severity: incident.severity,
                            reportedAt: incident.reportedAt,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.incidentDetails,
                                arguments: {'incidentId': incident.incidentId},
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'incidents_fab',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.reportIncident);
            },
            backgroundColor: PremiumAppTheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}

