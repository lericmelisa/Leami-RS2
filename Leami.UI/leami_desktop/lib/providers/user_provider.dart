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

  Future<bool> passChange(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    final url = Uri.parse('$baseUrl/User/change-password');
    final body = jsonEncode({
      'userId': userId,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });

    final resp = await http.post(url, headers: getHeaders(), body: body);

    if (resp.statusCode == 401) {
      throw Exception('Niste autorizovani da promijenite lozinku.');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        AuthProvider.applyAuthFromDto(decoded);
        return (decoded['token'] ?? decoded['Token']) != null;
      }
    } catch (_) {}
    return false;
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

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      AuthProvider.applyAuthFromDto(decoded);
    }

    print(
      "PRIJAVLJENI ADMIN JE: ${const JsonEncoder.withIndent('  ').convert(jsonDecode(res.body))}",
    );
    return User.fromJson(jsonDecode(res.body));
  }

  Future<User> updateAdmin(int id, Map<String, dynamic> request) async {
    final uri = Uri.parse('$baseUrl/User/$id/admin');
    final headers = getHeaders();
    final body = jsonEncode(request);

    final resp = await http.put(uri, headers: headers, body: body);
    ensureValidResponseOrThrow(resp);

    final data = jsonDecode(resp.body);

    return fromJson(data);
  }
}
