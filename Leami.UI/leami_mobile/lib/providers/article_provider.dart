import 'dart:convert';

import 'package:leami_mobile/models/article.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ArticleProvider extends BaseProvider<Article> {
  ArticleProvider() : super("Article");

  @override
  Article fromJson(dynamic json) {
    return Article.fromJson(json);
  }

  Future<SearchResult<Article>> getRecommended(
    int articleId, {
    int take = 3,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint/$articleId/recommend?take=$take');
    final headers = getHeaders();
    final res = await http.get(uri, headers: headers);

    ensureValidResponseOrThrow(res);
    final data = jsonDecode(res.body);
    if (data is List) {
      return SearchResult<Article>(
        items: data.map<Article>((e) => fromJson(e)).toList(),
      );
    }
    throw Exception('Neočekivan JSON format za preporuke: $data');
  }
}
