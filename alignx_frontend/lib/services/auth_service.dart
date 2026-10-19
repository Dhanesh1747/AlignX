import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static final ValueNotifier<UserModel?> currentUserNotifier = ValueNotifier<UserModel?>(null);
  static final ValueNotifier<bool> isInitializedNotifier = ValueNotifier<bool>(false);

  static const String _userSessionKey = 'alignx_active_user_session';

  static UserModel? get currentUser => currentUserNotifier.value;
  static bool get isAuthenticated => currentUserNotifier.value != null;

  /// Initialize and restore existing session from storage
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(_userSessionKey);
      if (userDataStr != null && userDataStr.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(userDataStr);
        currentUserNotifier.value = UserModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Auth init error: $e");
    } finally {
      isInitializedNotifier.value = true;
    }
  }

  /// Sign In with Email & Password
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return {'success': false, 'message': 'Please enter both email and password.'};
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': cleanEmail, 'password': cleanPassword}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final user = UserModel(
            id: data['user']['id']?.toString() ?? 'user-demo',
            name: data['user']['name']?.toString() ?? 'Dhanesh Kumbharkar',
            email: data['user']['email']?.toString() ?? cleanEmail,
            token: data['token']?.toString(),
          );
          await _saveSession(user);
          return {'success': true, 'user': user, 'message': data['message'] ?? 'Login successful'};
        }
      } else if (response.statusCode == 401) {
        final Map<String, dynamic> err = json.decode(response.body);
        return {'success': false, 'message': err['message'] ?? 'Invalid credentials.'};
      }
    } catch (e) {
      debugPrint("Backend auth login error (using fallback): $e");
    }

    // Offline / Standalone Fallback Authentication
    if (cleanPassword.length < 6) {
      return {'success': false, 'message': 'Password must be at least 6 characters.'};
    }

    String displayName = "Dhanesh Kumbharkar";
    if (cleanEmail.contains('@')) {
      final prefix = cleanEmail.split('@')[0];
      if (prefix.isNotEmpty && prefix.toLowerCase() != 'dhanesh') {
        displayName = prefix[0].toUpperCase() + prefix.substring(1);
      }
    }

    final fallbackUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: displayName,
      email: cleanEmail,
      token: 'alignx_offline_token',
    );

    await _saveSession(fallbackUser);
    return {'success': true, 'user': fallbackUser, 'message': 'Welcome to AlignX!'};
  }

  /// Register New Account
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return {'success': false, 'message': 'Please fill all required fields.'};
    }

    if (cleanPassword.length < 6) {
      return {'success': false, 'message': 'Password must be at least 6 characters.'};
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'name': cleanName.isNotEmpty ? cleanName : cleanEmail.split('@')[0],
              'email': cleanEmail,
              'password': cleanPassword,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['user'] != null) {
          final user = UserModel(
            id: data['user']['id']?.toString() ?? 'user_reg',
            name: data['user']['name']?.toString() ?? cleanName,
            email: data['user']['email']?.toString() ?? cleanEmail,
            token: data['token']?.toString(),
          );
          await _saveSession(user);
          return {'success': true, 'user': user, 'message': data['message'] ?? 'Account created successfully!'};
        }
      } else if (response.statusCode == 409) {
        return {'success': false, 'message': 'An account with this email already exists.'};
      }
    } catch (e) {
      debugPrint("Backend auth register error (using fallback): $e");
    }

    // Offline / Standalone Fallback Registration
    final user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName.isNotEmpty ? cleanName : cleanEmail.split('@')[0],
      email: cleanEmail,
      token: 'alignx_offline_token',
    );

    await _saveSession(user);
    return {'success': true, 'user': user, 'message': 'Account created successfully!'};
  }

  /// Log out and invalidate local session
  static Future<void> logout() async {
    try {
      await http
          .post(Uri.parse('${ApiService.baseUrl}/auth/logout'))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userSessionKey);
    } catch (e) {
      debugPrint("Error clearing auth session: $e");
    }

    currentUserNotifier.value = null;
  }

  static Future<void> _saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userSessionKey, json.encode(user.toJson()));
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
    currentUserNotifier.value = user;
  }
}
