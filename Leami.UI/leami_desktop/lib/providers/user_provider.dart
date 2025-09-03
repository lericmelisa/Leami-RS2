import 'dart:convert';

import 'package:leami_desktop/models/user.dart';
import 'package:leami_desktop/providers/auth_provider.dart';
import 'package:leami_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("User");

  @override
  User fromJson(dynamic json) {
    return User.fromJson(json);
  }

  Future<User> getById(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/User/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (AuthProvider.token != null)
          'Authorization': 'Bearer ${AuthProvider.token}',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Greška ${res.statusCode}: ${res.body}');
    }
    print(
      "PRIJAVLJENI ADMIN JE: ${const JsonEncoder.withIndent('  ').convert(jsonDecode(res.body))}",
    );
    return User.fromJson(jsonDecode(res.body));
  }
}
