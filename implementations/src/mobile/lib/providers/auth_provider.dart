import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;
  String? get role => _user?['role'];
  String? get userId => _user?['id']?.toString();
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    try {
      final response = await ApiService.post('/auth/login', body: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          _user = Map<String, dynamic>.from(data['user']);
          if (_user!['role'] != null) {
            _user!['role'] = (_user!['role'] as String).toLowerCase();
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(_user));
          notifyListeners();
        } else {
          throw Exception(data['message'] ?? 'Login failed - no user data');
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Login failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    try {
      final response = await ApiService.post('/auth/register', body: userData);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['userId'] != null) {
          await login(userData['email'], userData['password']);
        } else {
          throw Exception(data['message'] ?? 'Registration failed');
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.post('/auth/logout', body: {});
    } catch (_) {
      // ignore logout failures
    }
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await ApiService.clearCookies();
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    try {
      await ApiService.init();
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('user')) return;

      final userJson = prefs.getString('user');
      if (userJson != null) {
        _user = jsonDecode(userJson) as Map<String, dynamic>;
        if (_user!['role'] != null) {
          _user!['role'] = (_user!['role'] as String).toLowerCase();
        }
        notifyListeners();

        final response = await ApiService.get('/auth/me');
        if (response.statusCode != 200) {
          await logout();
          return;
        }

        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          _user = Map<String, dynamic>.from(data['user']);
          if (_user!['role'] != null) {
            _user!['role'] = (_user!['role'] as String).toLowerCase();
          }
          await prefs.setString('user', jsonEncode(_user));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Auto login error: $e');
      await logout();
    }
  }
}