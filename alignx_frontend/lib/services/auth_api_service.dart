import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';
import 'backend_config.dart';

class AuthApiService {
  static const _tokenKey = 'alignx_access_token';

  static Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) => _authenticate('register', {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      });

  static Future<AuthSession> login({
    required String email,
    required String password,
  }) => _authenticate('login', {
        'email': email.trim(),
        'password': password,
      });

  static Future<AuthSession> _authenticate(
      String route, Map<String, String> body) async {
    final response = await http
        .post(
          Uri.parse('${BackendConfig.baseUrl}/auth/$route'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    final data = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_messageFrom(data, response.statusCode));
    }
    final session = AuthSession.fromJson(data);
    if (session.token.isEmpty) {
      throw const AuthApiException('The server returned an invalid session.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, session.token);
    return session;
  }

  static Future<AuthSession?> restoreSession() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString(_tokenKey);
      if (token == null || token.isEmpty) return null;
      final response = await http
          .get(
            Uri.parse('${BackendConfig.baseUrl}/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        await preferences.remove(_tokenKey);
        return null;
      }
      return AuthSession.fromJson({..._decode(response.body), 'token': token});
    } catch (_) {
      // Keep the token so a temporary backend outage does not sign the user out.
      return null;
    }
  }

  static Future<String?> accessToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey);
    try {
      if (token != null && token.isNotEmpty) {
        await http
            .post(
              Uri.parse('${BackendConfig.baseUrl}/auth/logout'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 5));
      }
    } finally {
      await preferences.remove(_tokenKey);
    }
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String _messageFrom(Map<String, dynamic> data, int status) {
    final message = data['message']?.toString();
    if (message != null && message.isNotEmpty) return message;
    if (status >= 500) return 'The server could not complete the request.';
    return 'Request failed. Check your details and try again.';
  }
}
