// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItemRequest _$OrderItemRequestFromJson(Map<String, dynamic> json) =>
    OrderItemRequest(
      articleId: (json['articleId'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );

Map<String, dynamic> _$OrderItemRequestToJson(OrderItemRequest instance) =>
    <String, dynamic>{
      'articleId': instance.articleId,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
    };
