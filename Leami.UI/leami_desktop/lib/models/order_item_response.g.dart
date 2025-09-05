// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItemResponse _$OrderItemResponseFromJson(Map<String, dynamic> json) =>
    OrderItemResponse(
      orderItemId: (json['orderItemId'] as num).toInt(),
      articleId: (json['articleId'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      article: Article.fromJson(json['article'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrderItemResponseToJson(OrderItemResponse instance) =>
    <String, dynamic>{
      'orderItemId': instance.orderItemId,
      'articleId': instance.articleId,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'total': instance.total,
      'article': instance.article,
    };
