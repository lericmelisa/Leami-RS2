import 'package:json_annotation/json_annotation.dart';
part 'article_category.g.dart';

@JsonSerializable()
class ArticleCategory {
  int categoryId;
  String categoryName;

  ArticleCategory({this.categoryId = 0, this.categoryName = ''});

  // factory koji poziva generated funkciju
  factory ArticleCategory.fromJson(Map<String, dynamic> json) =>
      _$ArticleCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleCategoryToJson(this);
}
