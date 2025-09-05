import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:leami_mobile/models/user.dart';
import 'dart:developer' as dev;

import 'package:leami_mobile/models/user_role.dart';

class AuthProvider {
  static String? token;
  static int? id;
  static User? user;
  static const envDefault = 'http://10.0.2.2:5139';
  static const baseUrl = String.fromEnvironment(
    'baseUrl',
    defaultValue: envDefault,
  );

  static Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/User/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Email': email, 'Password': password}),
      );

      dev.log('[LOGIN] ${response.statusCode} ${response.body}');
      if (response.statusCode != 200) return false;

      final Map<String, dynamic> j = json.decode(response.body);

      final rawToken = (j['token'] ?? j['Token']) as String?;
      if (rawToken == null || rawToken.isEmpty) return false;
      token = rawToken;

      final r = j['role'];
      final role = r == null
          ? null
          : UserRole(
              id: r['roleid'] ?? r['id'],
              name: r['roleName'] ?? r['name'],
            );

      user = User(
        id: j['id'],
        firstName: j['firstName'],
        lastName: j['lastName'],
        email: j['email'],
        username: j['username'],
        createdAt: DateTime.tryParse(j['created'] ?? '') ?? DateTime.now(),
        lastLoginAt:
            DateTime.tryParse(j['lastLoginAt'] ?? '') ?? DateTime.now(),
        phoneNumber: j['phoneNumber'],
        userImage: j['userImage'],
        role: role,
      );

      dev.log('[LOGIN] token len=${token!.length}, userId=${user!.id}');
      return true;
    } catch (e, st) {
      dev.log('[LOGIN] EX: $e\n$st');
      return false;
    }
  }

  static void logout() {
    token = null;
  }

  static void applyAuthFromDto(Map<String, dynamic> j) {
    // 1) Token (backend može vratiti "token" ili "Token")
    final rawToken = (j['token'] ?? j['Token']) as String?;
    if (rawToken != null && rawToken.isNotEmpty) {
      token = rawToken;
      dev.log('[AUTH] novi token postavljen (len=${token!.length})');
    }
  }

  static bool get isAuthenticated => token != null;

  static Future<void> logoutApi() async {
    if (token == null) return;
    try {
      final url = Uri.parse('$baseUrl/User/logout');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      dev.log('logoutApi error: $e');
    }
  }

  static Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/User/Registration');
    final body = {
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'Password': password,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    // 2xx -> ok
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }

    // 409 -> email u upotrebi
    if (response.statusCode == 409) {
      throw Exception('HTTP 409: Email already in use');
    }

    // Ako backend nekad vrati 500 s porukom "već postoji"
    final lower = response.body.toLowerCase();
    if (response.statusCode == 500 &&
        (lower.contains('već postoji') || lower.contains('already exists'))) {
      throw Exception('HTTP 409: Email already in use');
    }

    // ostale greške
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
}
