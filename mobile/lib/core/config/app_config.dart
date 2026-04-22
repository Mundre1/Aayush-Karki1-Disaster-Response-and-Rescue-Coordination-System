class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  // For Android emulator, use: 'http://10.0.2.2:5000/api'
  // For iOS simulator, use: 'http://localhost:5000/api'
  // For physical device, use your computer's IP: 'http://192.168.x.x:5000/api'

  static const String socketUrl = 'http://10.0.2.2:5000';

  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String incidentsEndpoint = '/incidents';
  static const String adminEndpoint = '/admin';
  static const String rescueTeamsEndpoint = '/rescue-teams';
  static const String respondersEndpoint = '/responders';
  static const String volunteersEndpoint = '/volunteers';
  static const String notificationsEndpoint = '/notifications';
  static const String donationsEndpoint = '/donations';
  static const String donationsEsewaInitiate = '/donations/esewa/initiate';
  static const String donationsEsewaConfirm = '/donations/esewa/confirm';
  static const String donationsEsewaFail = '/donations/esewa/fail';
  static const String donationsBankInfo = '/donations/bank-info';
  static const String adminDonationsBankPending = '/admin/donations/bank/pending';
  static String adminDonationBankConfirm(int donationId) =>
      '/admin/donations/bank/$donationId/confirm';
  static String adminDonationBankReject(int donationId) =>
      '/admin/donations/bank/$donationId/reject';
  
  static const String campaignsEndpoint = '/campaigns';
  static String campaignStatusUpdate(int id) => '/campaigns/$id/status';

  static const String adminVolunteerMissionRequests =
      '/admin/volunteer-mission-requests';
  static String adminVolunteerMissionRequestApprove(int requestId) =>
      '/admin/volunteer-mission-requests/$requestId/approve';
  static String adminVolunteerMissionRequestReject(int requestId) =>
      '/admin/volunteer-mission-requests/$requestId/reject';
  static String adminVerifyIncident(int incidentId) =>
      '/admin/incidents/$incidentId/verify';

  // Esewa Configuration (Test / UAT environment)
  static const String esewaProductCode = 'EPAYTEST';
  static const String esewaSecretKey = '8gBm/:&EnhH.1/q';
  static const String esewaSuccessUrl = 'https://developer.esewa.com.np/success';
  static const String esewaFailureUrl = 'https://developer.esewa.com.np/failure';
  static const String esewaTaxAmount = '0';
  static const String esewaProductServiceCharge = '0';
  static const String esewaProductDeliveryCharge = '0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Hive Box Names
  static const String incidentsBox = 'incidents_box';
  static const String syncQueueBox = 'sync_queue_box';
  static const String userProfileBox = 'user_profile_box';
  static const String missionsBox = 'missions_box';
  static const String notificationsBox = 'notifications_box';

  // App Settings
  static const int locationUpdateInterval = 5; // seconds
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB

  // Map Configuration
  // Default center: Kathmandu, Nepal
  static const double defaultLatitude = 27.7172;
  static const double defaultLongitude = 85.3240;
  static const double defaultZoom = 13.0; // City level zoom
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  // OpenStreetMap tile URL
  static const String mapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
