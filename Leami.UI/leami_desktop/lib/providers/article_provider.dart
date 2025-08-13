import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leami_desktop/providers/auth_provider.dart';

class ArticleProvider extends ChangeNotifier {
  Future<dynamic> fetchArticles() async {
    var url = 'http://localhost:5139/Article';
    var response = await http.get(Uri.parse(url), headers: getHeaders());
    return response.body;
  }

  Map<String, String> getHeaders() {
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': "Bearer ${AuthProvider.token}",
    };
    print(AuthProvider.token);
    return headers;
  }
}
