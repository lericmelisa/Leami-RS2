import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leami_desktop/models/monthly_order.dart';
import 'package:leami_desktop/models/monthly_revenue.dart';
import 'package:leami_desktop/models/reports_summary.dart';
import 'package:http/http.dart' as http;
import 'package:leami_desktop/providers/auth_provider.dart';

class ReportProvider with ChangeNotifier {
  final String _baseUrl = const String.fromEnvironment(
    'baseUrl',
    defaultValue: 'http://localhost:5139',
  );

  bool isLoading = false;
  ReportsSummary? summary;
  List<MonthlyOrderData> ordersByMonth = [];
  List<MonthlyRevenueData> revenueByMonth = [];

  int _loadVersion = 0;
  Future<dynamic> _getJson(String path, [Map<String, String>? params]) async {
    final uri = Uri.parse('$_baseUrl/$path').replace(queryParameters: params);
    final headers = {
      'Content-Type': 'application/json',
      if (AuthProvider.token != null && AuthProvider.token!.isNotEmpty)
        'Authorization': 'Bearer ${AuthProvider.token}',
    };
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body);
  }

  Future<void> loadAll({DateTime? from, DateTime? to}) async {
    final myVersion = ++_loadVersion;
    debugPrint('>>> loadAll START (from=$from to=$to)');
    isLoading = true;
    notifyListeners();

    var effectiveFrom =
        from ?? DateTime.now().subtract(const Duration(days: 30));
    var effectiveTo = to ?? DateTime.now();

    if (effectiveFrom.isAfter(effectiveTo)) {
      final tmp = effectiveFrom;
      effectiveFrom = effectiveTo;
      effectiveTo = tmp;
    }

    Map<String, String> params = {
      'from': DateFormat('yyyy-MM-dd').format(effectiveFrom),
      'to': DateFormat('yyyy-MM-dd').format(effectiveTo),
    };
    try {
      print(
        '>> _pickDate called: isFrom=$effectiveFrom, from=$effectiveFrom, to=$effectiveTo',
      );

      final results = await Future.wait([
        _getJson('Reports/stats', params),
        _getJson('Reports/orders-by-month', params),
        _getJson('Reports/revenue-by-month', params),
      ]);

      if (myVersion != _loadVersion) {
        debugPrint('>>> loadAll (v$myVersion) stale, ignoring results');
        return;
      }

      // Parse
      final statsJson = results[0] as Map<String, dynamic>;
      final ordersJson = results[1] as List;
      final revenueJson = results[2] as List;

      summary = ReportsSummary.fromJson(statsJson);
      ordersByMonth = ordersJson
          .map((e) => MonthlyOrderData.fromJson(e as Map<String, dynamic>))
          .toList();
      revenueByMonth = revenueJson
          .map((e) => MonthlyRevenueData.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint(
        '>>> loadAll (v$myVersion) OK: '
        'orders=${ordersByMonth.length}, revenue=${revenueByMonth.length}',
      );
    } catch (e, st) {
      if (myVersion == _loadVersion) {
        debugPrint('DEBUG: Error in loadAll(v$myVersion): $e');
        debugPrint('DEBUG: StackTrace: $st');
      } else {
        debugPrint('DEBUG: Error from stale loadAll(v$myVersion): $e');
      }
    } finally {
      // Gasimo loader samo ako gasimo "zadnji" aktivni poziv
      if (myVersion == _loadVersion) {
        isLoading = false;
        notifyListeners();
      }
      debugPrint('<<< loadAll END (v$myVersion)');
    }
  }

  Future<Uint8List> downloadReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final df = DateFormat('yyyy-MM-dd');
    final qs = {'from': df.format(from), 'to': df.format(to)};

    final uri = Uri.parse(
      '$_baseUrl/Reports/download',
    ).replace(queryParameters: qs);

    final headers = {
      'Accept': 'application/pdf',
      if (AuthProvider.token != null && AuthProvider.token!.isNotEmpty)
        'Authorization': 'Bearer ${AuthProvider.token}',
    };
    debugPrint('[PDF] GET $uri');
    debugPrint(
      '[PDF] token present: ${AuthProvider.token != null && AuthProvider.token!.isNotEmpty}',
    );
    debugPrint('[PDF] headers: $headers');

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      debugPrint('PDF body: ${resp.body}');
      throw Exception('PDF download failed ${resp.statusCode}');
    }
    return resp.bodyBytes;
  }

  void clear() {
    summary = null;
    ordersByMonth = [];
    revenueByMonth = [];
    notifyListeners();
  }
}
