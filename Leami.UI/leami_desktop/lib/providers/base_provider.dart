import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:http/http.dart' as http;
import 'package:leami_desktop/providers/auth_provider.dart';
import 'package:http/http.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? _baseUrl;
  String _endpoint = "";

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
    _baseUrl = const String.fromEnvironment(
      "baseUrl",
      defaultValue: "http://localhost:5139 ",
    );
  }

  String get baseUrl => _baseUrl!;
  String get endpoint => _endpoint;

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = '$_baseUrl/$_endpoint';

    if (filter != null) {
      var query = getQueryString(filter);
      url += '?$query';
    }

    var uri = Uri.parse(url);
    var headers = getHeaders();

    var response = await http.get(uri, headers: headers);
    debugPrint(response.body);

    ensureValidResponseOrThrow(response);
    final data = jsonDecode(response.body);

    if (data is List) {
      return SearchResult<T>(
        items: data.map<T>((item) => fromJson(item)).toList(),
      );
    }

    throw Exception("Neočekivan JSON format: $data");
  }

  void clear() {
    notifyListeners();
  }

  Future<T> insert(dynamic request) async {
    final url = "$_baseUrl/$_endpoint";
    final uri = Uri.parse(url);
    final headers = getHeaders();

    final jsonRequest = jsonEncode(request);
    dev.log('POST $uri', name: 'HTTP');
    dev.log('Headers: $headers', name: 'HTTP');
    dev.log('Body: $jsonRequest', name: 'HTTP');

    final response = await http.post(uri, headers: headers, body: jsonRequest);

    dev.log('Status: ${response.statusCode}', name: 'HTTP');
    dev.log('Body: ${response.body}', name: 'HTTP');

    ensureValidResponseOrThrow(response);

    final data = _safeJsonDecode(response.body);
    return fromJson(data);
  }

  Future<T> update(int id, [dynamic request]) async {
    final url = "$_baseUrl/$_endpoint/$id";
    final uri = Uri.parse(url);
    final headers = getHeaders();

    final jsonRequest = jsonEncode(request);
    dev.log('PUT $uri', name: 'HTTP');
    dev.log('Headers: $headers', name: 'HTTP');
    dev.log('Body: $jsonRequest', name: 'HTTP');

    final response = await http.put(uri, headers: headers, body: jsonRequest);
    debugPrint("📤 JSON Request KOJI SALJEM NA SERVER: $jsonRequest");

    ensureValidResponseOrThrow(response);

    final data = _safeJsonDecode(response.body);
    return fromJson(data);
  }

  Future<bool> delete(int id) async {
    // Backend očekuje query parametar ?id=
    final url = "$_baseUrl/$_endpoint?id=$id";
    final uri = Uri.parse(url);
    final headers = getHeaders();

    dev.log('DELETE $uri', name: 'HTTP');
    dev.log('Headers: $headers', name: 'HTTP');

    final response = await http.delete(uri, headers: headers);

    dev.log('Status: ${response.statusCode}', name: 'HTTP');
    dev.log('Body: ${response.body}', name: 'HTTP');

    ensureValidResponseOrThrow(response);

    return response.body.toLowerCase().contains("true");
  }

  void ensureValidResponseOrThrow(Response response) {
    final code = response.statusCode;
    if (code >= 200 && code <= 299) return;

    // Pokušaj pročitati poruku iz JSON-a
    String message = response.body;
    try {
      final j = jsonDecode(response.body);
      if (j is Map && j['message'] != null) {
        message = j['message'].toString();
      } else if (j is Map && j['error'] != null) {
        message = j['error'].toString();
      }
    } catch (_) {
      // zadrži raw body
    }

    if (code == 401) {
      throw Exception('Unauthorized (401): $message');
    }
    if (code == 403) {
      throw Exception('Forbidden (403): $message');
    }
    if (code == 404) {
      throw Exception('Not Found (404): $message');
    }
    if (code == 500) {
      throw Exception('Server error (500): $message');
    }
    throw Exception('HTTP $code: $message');
  }

  dynamic _safeJsonDecode(String body) {
    if (body.isEmpty) return {};
    try {
      return jsonDecode(body);
    } catch (e) {
      throw Exception('Nevažeći JSON: $e\nBody: $body');
    }
  }

  T fromJson(data) {
    throw Exception("Method not implemented");
  }

  Map<String, String> getHeaders() {
    final token = AuthProvider.token;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    dev.log(
      'Token present: ${token != null && token.isNotEmpty}',
      name: 'AUTH',
    );
    return headers;
  }

  String getQueryString(
    Map params, {
    String prefix = '&',
    bool inRecursion = false,
  }) {
    String query = '';
    params.forEach((key, value) {
      var k = key;
      if (inRecursion) {
        if (k is int) {
          k = '[$k]';
        } else if (value is List || value is Map) {
          k = '.$k';
        } else {
          k = '.$k';
        }
      }
      if (value is String || value is int || value is double || value is bool) {
        var encoded = value is String ? Uri.encodeComponent(value) : value;
        query += '$prefix$k=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$k=${value.toIso8601String()}';
      } else if (value is List || value is Map) {
        final map = value is List ? value.asMap() : (value as Map);
        map.forEach((kk, vv) {
          query += getQueryString(
            {kk: vv},
            prefix: '$prefix$k',
            inRecursion: true,
          );
        });
      }
    });
    return query;
  }
}
