// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArticleCategory _$ArticleCategoryFromJson(Map<String, dynamic> json) =>
    ArticleCategory(
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
    );

Map<String, dynamic> _$ArticleCategoryToJson(ArticleCategory instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
    };
