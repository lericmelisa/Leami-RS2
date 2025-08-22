import 'package:leami_desktop/models/article_category.dart';
import 'package:leami_desktop/providers/base_provider.dart';

class ArticleCategoryProvider extends BaseProvider<ArticleCategory> {
  ArticleCategoryProvider() : super("Category");

  @override
  ArticleCategory fromJson(dynamic json) {
    return ArticleCategory.fromJson(json);
  }
}
