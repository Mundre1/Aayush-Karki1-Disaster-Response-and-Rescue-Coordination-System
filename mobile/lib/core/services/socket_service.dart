import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class SocketService {
  late io.Socket socket;
  bool _isConnected = false;

  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  void connect(String token, int userId, int roleId) {
    if (_isConnected) {
      debugPrint('Socket already connected');
      return;
    }

    try {
      socket = io.io(AppConfig.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'extraHeaders': {'authorization': 'Bearer $token'}
      });

      socket.connect();

      socket.onConnect((_) {
        debugPrint('Connected to socket server');
        _isConnected = true;

        // Join user-specific room
        joinUserRoom(userId);

        // Join role-specific room
        joinRoleRoom(roleId);
      });

      socket.onDisconnect((_) {
        debugPrint('Disconnected from socket server');
        _isConnected = false;
      });

      socket.onConnectError((error) {
        debugPrint('Socket connection error: $error');
        _isConnected = false;
      });

      socket.onError((error) {
        debugPrint('Socket error: $error');
        _isConnected = false;
      });

    } catch (e) {
      debugPrint('Failed to initialize socket: $e');
    }
  }

  void disconnect() {
    if (_isConnected) {
      socket.disconnect();
      _isConnected = false;
    }
  }

  void joinUserRoom(int userId) {
    if (_isConnected) {
      socket.emit('join_user_room', userId);
      debugPrint('Joined user room: $userId');
    }
  }

  void joinRoleRoom(int roleId) {
    if (_isConnected) {
      socket.emit('join_role_room', roleId);
      debugPrint('Joined role room: $roleId');
    }
  }

  void sendLocationUpdate(int missionId, double latitude, double longitude, int userId) {
    if (_isConnected) {
      socket.emit('location_update', {
        'missionId': missionId,
        'latitude': latitude,
        'longitude': longitude,
        'userId': userId,
      });
    }
  }

  void sendMissionStatusUpdate(int missionId, String status, int userId) {
    if (_isConnected) {
      socket.emit('mission_status_update', {
        'missionId': missionId,
        'status': status,
        'userId': userId,
      });
    }
  }

  void sendVolunteerRequest(Map<String, dynamic> volunteerData) {
    if (_isConnected) {
      socket.emit('volunteer_request', volunteerData);
    }
  }

  void sendDonationUpdate(Map<String, dynamic> donationData) {
    if (_isConnected) {
      socket.emit('donation_received', donationData);
    }
  }

  // Listen for events
  void onNewIncident(Function(dynamic) callback) {
    socket.on('new_incident', callback);
  }

  void onMissionAssigned(Function(dynamic) callback) {
    socket.on('mission_assigned', callback);
  }

  void onMissionStatusChanged(Function(dynamic) callback) {
    socket.on('mission_status_changed', callback);
  }

  void onRescueTeamLocation(Function(dynamic) callback) {
    if (_isConnected) {
      socket.on('responder_location', callback);
      socket.on('rescue_team_location', callback);
    }
  }

  void onNotification(Function(dynamic) callback) {
    socket.on('notification', callback);
  }

  void onNewDonation(Function(dynamic) callback) {
    socket.on('new_donation', callback);
  }

  void onDonationConfirmed(Function(dynamic) callback) {
    socket.on('donation_confirmed', callback);
  }

  // Remove listeners
  void offNewIncident() {
    socket.off('new_incident');
  }

  void offMissionAssigned() {
    socket.off('mission_assigned');
  }

  void offMissionStatusChanged() {
    socket.off('mission_status_changed');
  }

  void offRescueTeamLocation() {
    if (_isConnected) {
      socket.off('responder_location');
      socket.off('rescue_team_location');
    }
  }

  void offNotification() {
    socket.off('notification');
  }

  bool get isConnected => _isConnected;
}
