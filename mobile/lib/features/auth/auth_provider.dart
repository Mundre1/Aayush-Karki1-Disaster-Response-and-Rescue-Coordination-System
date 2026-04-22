import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'models/user_model.dart';
import '../../core/services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  Future<void> initialize() async {
    _user = await _authService.getCurrentUser();

    if (_user != null) {
      final token = await _authService.getToken();
      if (token != null) {
        SocketService().connect(token, _user!.userId, _user!.roleId);
      }
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);

      if (result['success'] == true) {
        _user = result['user'] as UserModel;

        // Connect to socket server for real-time updates
        final token = result['token'] as String?;
        if (token != null && _user != null) {
          SocketService().connect(token, _user!.userId, _user!.roleId);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String roleName,
    String? phone,
    String? organizationChoice,
    int? organizationId,
    String? organizationName,
    String? organizationContact,
    String? organizationSpecialization,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        roleName: roleName,
        phone: phone,
        organizationChoice: organizationChoice,
        organizationId: organizationId,
        organizationName: organizationName,
        organizationContact: organizationContact,
        organizationSpecialization: organizationSpecialization,
      );

      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableOrganizations() async {
    return _authService.getAvailableOrganizations();
  }

  Future<void> logout() async {
    // Disconnect from socket server
    SocketService().disconnect();

    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> isAuthenticated() async {
    final authenticated = await _authService.isAuthenticated();
    if (authenticated) {
      await initialize();
    }
    return authenticated;
  }

  Future<bool> updateProfile({required String name, String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.updateProfile(name: name, phone: phone);

      if (result['success'] == true) {
        final updatedUser = result['user'] as UserModel;
        _user = UserModel(
          userId: updatedUser.userId,
          name: updatedUser.name,
          email: updatedUser.email,
          phone: updatedUser.phone,
          roleId: updatedUser.roleId,
          roleName: updatedUser.roleName ?? _user?.roleName,
          createdAt: updatedUser.createdAt ?? _user?.createdAt,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
