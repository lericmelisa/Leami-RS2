import 'dart:developer' as developer;

import 'package:leami_mobile/models/article.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/providers/article_provider.dart';

class LoggedArticleProvider extends ArticleProvider {
  @override
  Future<SearchResult<Article>> get({dynamic filter}) async {
    developer.log("Fetching articles from LoggedArticleProvider");

    try {
      final result = await super.get(filter: filter);

      return result;
    } catch (e) {
      developer.log("Error fetching articles: $e", error: e);
      rethrow; // Propagate the error
    }
  }
}
