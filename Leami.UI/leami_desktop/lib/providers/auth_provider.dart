import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:leami_desktop/models/user.dart';
import 'package:leami_desktop/models/user_role.dart';

class ApiHeaders {
  static Map<String, String> json() {
    final h = <String, String>{'Content-Type': 'application/json'};
    final t = AuthProvider.token;
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }
}

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
        jobTitle: j['jobTitle'],
        hireDate: _parseDate(j['hireDate'] ?? j['HireDate']),
        note: j['note'],
      );
      final pretty = const JsonEncoder.withIndent(
        '  ',
      ).convert(AuthProvider.user?.toJson());
      dev.log(pretty, name: 'USERUSERUSERUSERUSER');

      dev.log('[LOGIN] token len=${token!.length}, userId=${user!.id}');
      return true;
    } catch (e, st) {
      dev.log('[LOGIN] EX: $e\n$st');
      return false;
    }
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  static void logout() {
    token = null;
    user = null;
    email = null;
    password = null;
  }

  static void applyAuthFromDto(Map<String, dynamic> j) {
    // 1) Token (backend može vratiti "token" ili "Token")
    final rawToken = (j['token'] ?? j['Token']) as String?;
    if (rawToken != null && rawToken.isNotEmpty) {
      token = rawToken;
      dev.log('[AUTH] novi token postavljen (len=${token!.length})');
    }

    // 2) (opcionalno) Osvježi user-a ako dobijemo DTO
    try {
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
        jobTitle: j['jobTitle'],
        hireDate: _parseDate(j['hireDate'] ?? j['HireDate']),
        note: j['note'],
      );

      dev.log('[USER] [USER] ${user!})');
    } catch (e) {
      // ako struktura nije kompletna, samo preskoči update usera
      dev.log('[AUTH] nije moguće obnoviti user iz DTO-a: $e');
    }
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
