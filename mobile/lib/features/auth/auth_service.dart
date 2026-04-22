import 'dart:convert';
import '../../core/services/api_service.dart';
import 'models/user_model.dart';
import '../../core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> register({
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
    try {
      final response = await _apiService.post(
        '${AppConfig.authEndpoint}/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'roleName': roleName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (organizationChoice != null) 'organizationChoice': organizationChoice,
          if (organizationId != null) 'organizationId': organizationId,
          if (organizationName != null && organizationName.isNotEmpty)
            'organizationName': organizationName,
          if (organizationContact != null && organizationContact.isNotEmpty)
            'organizationContact': organizationContact,
          if (organizationSpecialization != null &&
              organizationSpecialization.isNotEmpty)
            'organizationSpecialization': organizationSpecialization,
        },
      );

      final data = response.data;

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableOrganizations() async {
    try {
      final response = await _apiService.get(
        '${AppConfig.authEndpoint}/organizations',
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final organizations = data['organizations'] as List<dynamic>? ?? [];
        return organizations
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConfig.authEndpoint}/login',
        body: {'email': email, 'password': password},
      );

      final data = response.data;

      if (response.statusCode == 200) {
        await _apiService.setToken(data['token']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.userKey, jsonEncode(data['user']));

        return {
          'success': true,
          'message': data['message'],
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.userKey);
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConfig.userKey);
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _apiService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return _apiService.getToken();
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.authEndpoint}/profile',
        body: {'name': name, if (phone != null) 'phone': phone},
      );

      final data = response.data;

      if (response.statusCode == 200) {
        final updatedUser = UserModel.fromJson(data['user']);
        final prefs = await SharedPreferences.getInstance();
        final existingJson = prefs.getString(AppConfig.userKey);
        if (existingJson != null) {
          try {
            final existing = jsonDecode(existingJson) as Map<String, dynamic>;
            existing['name'] = updatedUser.name;
            existing['email'] = updatedUser.email;
            existing['phone'] = updatedUser.phone;
            existing['roleId'] = updatedUser.roleId;
            if (updatedUser.roleName != null) {
              existing['roleName'] = updatedUser.roleName;
            }
            await prefs.setString(AppConfig.userKey, jsonEncode(existing));
          } catch (_) {
            await prefs.setString(
              AppConfig.userKey,
              jsonEncode(updatedUser.toJson()),
            );
          }
        } else {
          await prefs.setString(
            AppConfig.userKey,
            jsonEncode(updatedUser.toJson()),
          );
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'user': updatedUser,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
