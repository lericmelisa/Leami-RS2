import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:leami_mobile/models/user.dart';
import 'dart:developer' as dev;

class AuthProvider {
  static String? token;
  static int? Id;
  static User? user;
  static Future<bool> login(String email, String password) async {
    // 1) Učitaj environment URL ili default
    const envDefault = 'http://10.0.2.2:5139';
    const envUrl = String.fromEnvironment('baseUrl', defaultValue: envDefault);

    // 2) Mapiranje za Android emulator
    final baseUrl = (!kIsWeb && Platform.isAndroid)
        ? Uri.parse(envUrl).replace(host: '10.0.2.2').toString()
        : envUrl;

    // 3) Sastavi punu login rutu
    final uri = Uri.parse('$baseUrl/User/login');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Email': email, 'Password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        token = data['token'] as String;
        Id = data['id'] as int;
        dev.log('Token: $token', name: 'AUTH');
        dev.log('User ID: $Id', name: 'AUTH');
        // Parsiranje korisnika iz odgovora
        user = User(
          id: data['id'],
          firstName: data['firstName'],
          lastName: data['lastName'],
          email: data['email'],
          username: data['username'],
          createdAt: DateTime.parse(data['created']),
          lastLoginAt: DateTime.parse(data['lastLoginAt']),
          phoneNumber: data['phoneNumber'],
          userImage: data['userImage'],
        );
        dev.log('$user', name: 'USER');
        return true;
      } else {
        print('Login failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  static void logout() {
    token = null;
  }

  static bool get isAuthenticated => token != null;
}
