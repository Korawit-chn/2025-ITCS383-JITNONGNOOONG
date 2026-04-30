import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class ApiService {
  static final http.Client _client = http.Client();
  static final Map<String, String> _cookies = {};
  static SharedPreferences? _prefs;
  static const _cookieStorageKey = 'api_cookies';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final saved = _prefs?.getString(_cookieStorageKey);
    if (saved != null && saved.isNotEmpty) {
      try {
        final decoded = jsonDecode(saved) as Map<String, dynamic>;
        _cookies.clear();
        decoded.forEach((key, value) {
          if (value is String) _cookies[key] = value;
        });
      } catch (_) {
        _cookies.clear();
      }
    }
  }

  static Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    final cookie = _cookieHeader();
    if (cookie != null) headers['Cookie'] = cookie;
    return headers;
  }

  static String? _cookieHeader() {
    if (_cookies.isEmpty) return null;
    return _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  static void _saveCookiesFromResponse(http.BaseResponse response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;
    final parts = raw.split(RegExp(r', (?=[^ ;]+=)'));
    var changed = false;
    for (final part in parts) {
      final cookiePart = part.split(';').first.trim();
      final separatorIndex = cookiePart.indexOf('=');
      if (separatorIndex > 0) {
        final key = cookiePart.substring(0, separatorIndex).trim();
        final value = cookiePart.substring(separatorIndex + 1).trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          if (_cookies[key] != value) {
            _cookies[key] = value;
            changed = true;
          }
        }
      }
    }
    if (changed) {
      _persistCookies();
    }
  }

  static Future<void> _persistCookies() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_cookieStorageKey, jsonEncode(_cookies));
  }

  static Future<http.Response> get(String path) async {
    await init();
    final uri = Uri.parse(path.startsWith('http') ? path : '${Config.apiBase}$path');
    final response = await _client.get(uri, headers: _headers(json: false));
    _saveCookiesFromResponse(response);
    return response;
  }

  static Future<http.Response> post(String path, {Object? body, bool jsonBody = true}) async {
    await init();
    final uri = Uri.parse(path.startsWith('http') ? path : '${Config.apiBase}$path');
    final response = await _client.post(uri,
        headers: _headers(json: jsonBody), body: jsonBody && body != null ? jsonEncode(body) : body);
    _saveCookiesFromResponse(response);
    return response;
  }

  static Future<http.Response> put(String path, {Object? body, bool jsonBody = true}) async {
    await init();
    final uri = Uri.parse(path.startsWith('http') ? path : '${Config.apiBase}$path');
    final response = await _client.put(uri,
        headers: _headers(json: jsonBody), body: jsonBody && body != null ? jsonEncode(body) : body);
    _saveCookiesFromResponse(response);
    return response;
  }

  static Future<http.Response> patch(String path, {Object? body, bool jsonBody = true}) async {
    await init();
    final uri = Uri.parse(path.startsWith('http') ? path : '${Config.apiBase}$path');
    final response = await _client.patch(uri,
        headers: _headers(json: jsonBody), body: jsonBody && body != null ? jsonEncode(body) : body);
    _saveCookiesFromResponse(response);
    return response;
  }

  static Future<http.Response> delete(String path, {Object? body}) async {
    await init();
    final uri = Uri.parse(path.startsWith('http') ? path : '${Config.apiBase}$path');
    final response = await _client.delete(uri,
        headers: _headers(json: body != null), body: body != null ? jsonEncode(body) : null);
    _saveCookiesFromResponse(response);
    return response;
  }

  static Future<http.StreamedResponse> postMultipart(
    String path, {
    required Map<String, String> fields,
    String? fileField,
    File? file,
  }) async {
    await init();
    final uri = Uri.parse(path.startsWith('http') ? path : '${Config.apiBase}$path');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers(json: false));
    request.fields.addAll(fields);
    if (fileField != null && file != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _saveCookiesFromResponse(response);
    return streamedResponse;
  }

  static Future<void> clearCookies() async {
    _cookies.clear();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_cookieStorageKey);
  }
}
