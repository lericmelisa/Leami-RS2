import 'package:json_annotation/json_annotation.dart';

part 'article.g.dart';

@JsonSerializable()
class Article {
  int articleId;
  String articleName;
  double articlePrice;
  String? articleDescription;
  String? articleImage;
  int? categoryId;

  Article({
    this.articleId = 0,
    this.articleName = '',
    this.articlePrice = 0,
    this.articleDescription = '',
    this.articleImage = '',
    this.categoryId = 0,
  });

  //ovoje za pojedinacni objekat sad treba odradit za listu
  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);
}
