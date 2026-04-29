import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Config.apiBase}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['user'] != null) {
        _user = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user));
        notifyListeners();
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } else {
      throw Exception('Login failed');
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
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
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('user')) return;

    _user = jsonDecode(prefs.getString('user')!);
    notifyListeners();
  }
}