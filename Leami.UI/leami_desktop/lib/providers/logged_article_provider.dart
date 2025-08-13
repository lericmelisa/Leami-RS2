import 'package:leami_desktop/providers/article_provider.dart';
import 'dart:developer' as developer;

class LoggedArticleProvider extends ArticleProvider {
  @override
  Future<dynamic> fetchArticles() async {
    developer.log("Fetching articles from LoggedArticleProvider");

    try {
      final startTime = DateTime.now();
      final result = await super.fetchArticles();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      developer.log(
        "Articles fetched successfully in ${duration.inMilliseconds} ms",
        name: 'logged_article_provider ',
      );
      print("USAOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");

      if (result is List) {
        developer.log(
          "Fetched articles: $result",
          name: 'logged_article_provider',
        );
      } else if (result is Map) {
        developer.log(
          "Fetched articles successfully",
          name: 'logged_article_provider',
        );
      }

      return result;
    } catch (e) {
      developer.log("Error fetching articles: $e", error: e);
      rethrow; // Propagate the error
    }
  }
}
