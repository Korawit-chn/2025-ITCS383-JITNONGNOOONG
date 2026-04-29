import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;
  String? get role => _user?['role'];
  String? get userId => _user?['id']?.toString();
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBase}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login response: $data');
        
        if (data['user'] != null) {
          _user = Map<String, dynamic>.from(data['user']);
          // Ensure role is lowercase
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
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBase}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['userId'] != null) {
          // After register, login automatically
          await login(userData['email'], userData['password']);
        } else {
          throw Exception(data['message'] ?? 'Registration failed');
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('user')) return;

      final userJson = prefs.getString('user');
      if (userJson != null) {
        _user = jsonDecode(userJson) as Map<String, dynamic>;
        // Ensure role is lowercase
        if (_user!['role'] != null) {
          _user!['role'] = (_user!['role'] as String).toLowerCase();
        }
        notifyListeners();
      }
    } catch (e) {
      print('Auto login error: $e');
      await logout();
    }
  }
}