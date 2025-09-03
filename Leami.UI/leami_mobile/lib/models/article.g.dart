// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Article _$ArticleFromJson(Map<String, dynamic> json) => Article(
  articleId: (json['articleId'] as num?)?.toInt() ?? 0,
  articleName: json['articleName'] as String? ?? '',
  articlePrice: (json['articlePrice'] as num?)?.toDouble() ?? 0,
  articleDescription: json['articleDescription'] as String? ?? '',
  articleImage: json['articleImage'] as String? ?? '',
  categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ArticleToJson(Article instance) => <String, dynamic>{
  'articleId': instance.articleId,
  'articleName': instance.articleName,
  'articlePrice': instance.articlePrice,
  'articleDescription': instance.articleDescription,
  'articleImage': instance.articleImage,
  'categoryId': instance.categoryId,
};
