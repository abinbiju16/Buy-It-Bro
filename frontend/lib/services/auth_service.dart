import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  User? _currentUser;
  bool _isLoading = true;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userJsonStr = prefs.getString('current_user');
      if (userJsonStr != null) {
        _currentUser = User.fromJson(jsonDecode(userJsonStr));
      }
    } catch (e) {
      debugPrint('Error loading saved session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'display_name': displayName,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveSession(data['access_token'], data['user']);
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveSession(data['access_token'], data['user']);
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Invalid login credentials');
    }
  }

  Future<void> _saveSession(String token, Map<String, dynamic> userMap) async {
    _token = token;
    _currentUser = User.fromJson(userMap);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('current_user', jsonEncode(userMap));
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
    notifyListeners();
  }
}
