import 'package:leami_desktop/models/article.dart';
import 'package:leami_desktop/providers/base_provider.dart';

class ArticleProvider extends BaseProvider<Article> {
  ArticleProvider() : super("Article");

  @override
  Article fromJson(dynamic json) {
    return Article.fromJson(json);
  }
}
