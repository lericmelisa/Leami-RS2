

import 'package:leami_mobile/models/article.dart';
import 'package:leami_mobile/providers/base_provider.dart';

class ArticleProvider extends BaseProvider<Article> {
  ArticleProvider() : super("Article");

  @override
  Article fromJson(dynamic json) {
    return Article.fromJson(json);
  }
}
