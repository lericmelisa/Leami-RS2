import 'package:leami_mobile/models/article_category.dart';
import 'package:leami_mobile/providers/base_provider.dart';

class ArticleCategoryProvider extends BaseProvider<ArticleCategory> {
  ArticleCategoryProvider() : super("Category");

  @override
  ArticleCategory fromJson(dynamic json) {
    return ArticleCategory.fromJson(json);
  }
}
