import "package:http/http.dart" as http;
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:leami_desktop/models/user.dart';
import 'package:leami_desktop/models/user_role.dart';

class AuthProvider {
  static String? email;
  static String? password;
  static User? user;
  static String? token;

  static const String _baseUrl = String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://localhost:5139",
  );

  static Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse('$_baseUrl/User/login');
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
    user = null;
    email = null;
    password = null;
  }

  static bool get isAuthenticated => token != null;

  static Future<void> logoutApi() async {
    if (token == null) return;
    try {
      final url = Uri.parse('$_baseUrl/User/logout');
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
}
