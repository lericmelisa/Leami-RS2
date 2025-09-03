import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/providers/auth_provider.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? _baseUrl;
  String _endpoint = "";

  static BaseProvider? _instance;

  BaseProvider(String endpoint) {
    _endpoint = endpoint; // PAZI NA CASE: "/api/User" vs "User"
    _baseUrl = const String.fromEnvironment(
      'baseUrl',
      defaultValue: "http://localhost:5139",
    );

    _instance = this;
  }

  static BaseProvider get instance {
    if (_instance == null) {
      throw Exception("BaseProvider.instance nije inicijaliziran!");
    }
    return _instance!;
  }

  /// Ovo je jedini getter koji se koristi pri građenju URL‐ova
  String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      final uri = Uri.parse(_baseUrl!);
      return uri.replace(host: '10.0.2.2').toString();
    }
    return _baseUrl!;
  }

  String get endpoint => _endpoint;

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = '$baseUrl/$endpoint';

    if (filter != null) {
      final query = getQueryString(filter);
      url += '?$query';
    }

    final uri = Uri.parse(url);
    final headers = getHeaders();
    final response = await http.get(uri, headers: headers);

    ensureValidResponseOrThrow(response);
    final data = jsonDecode(response.body);

    if (data is List) {
      return SearchResult<T>(
        items: data.map<T>((item) => fromJson(item)).toList(),
      );
    }

    throw Exception("Neočekivan JSON format: $data");
  }

  Future<T> insert(dynamic request) async {
    final url = '$baseUrl/$endpoint';
    final uri = Uri.parse(url);
    final headers = getHeaders();
    final body = jsonEncode(request);

    dev.log('POST $uri', name: 'HTTP');
    dev.log('Headers: $headers', name: 'HTTP');
    dev.log('Body: $body', name: 'HTTP');

    final response = await http.post(uri, headers: headers, body: body);

    ensureValidResponseOrThrow(response);
    final data = _safeJsonDecode(response.body);
    return fromJson(data);
  }

  Future<T> update(int id, [dynamic request]) async {
    final url = '$baseUrl/$endpoint/$id';
    final uri = Uri.parse(url);
    final headers = getHeaders();
    final body = jsonEncode(request);

    dev.log('PUT $uri', name: 'HTTP');
    dev.log('Headers: $headers', name: 'HTTP');
    dev.log('Body: $body', name: 'HTTP');

    final response = await http.put(uri, headers: headers, body: body);

    ensureValidResponseOrThrow(response);
    final data = _safeJsonDecode(response.body);
    return fromJson(data);
  }

  Future<bool> delete(int id) async {
    final url = '$baseUrl/$endpoint?id=$id';
    final uri = Uri.parse(url);
    final headers = getHeaders();

    dev.log('DELETE $uri', name: 'HTTP');
    dev.log('Headers: $headers', name: 'HTTP');

    final response = await http.delete(uri, headers: headers);

    ensureValidResponseOrThrow(response);
    return response.body.toLowerCase().contains("true");
  }

  void ensureValidResponseOrThrow(Response response) {
    final code = response.statusCode;
    if (code >= 200 && code <= 299) return;

    String message = response.body;
    try {
      final j = jsonDecode(response.body);
      if (j is Map && j['message'] != null) {
        message = j['message'].toString();
      } else if (j is Map && j['error'] != null) {
        message = j['error'].toString();
      }
    } catch (_) {}

    switch (code) {
      case 401:
        throw Exception('Unauthorized (401): $message');
      case 403:
        throw Exception('Forbidden (403): $message');
      case 404:
        throw Exception('Not Found (404): $message');
      case 500:
        throw Exception('Server error (500): $message');
      default:
        throw Exception('HTTP $code: $message');
    }
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
      if (value is String || value is num || value is bool) {
        final encoded = value is String ? Uri.encodeComponent(value) : value;
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
