// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderRequest _$OrderRequestFromJson(Map<String, dynamic> json) => OrderRequest(
  userId: (json['userId'] as num).toInt(),
  orderDate: DateTime.parse(json['orderDate'] as String),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  paymentMethod: json['paymentMethod'] as String,
  orderItems: (json['orderItems'] as List<dynamic>)
      .map((e) => OrderItemRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OrderRequestToJson(OrderRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'orderDate': instance.orderDate.toIso8601String(),
      'totalAmount': instance.totalAmount,
      'paymentMethod': instance.paymentMethod,
      'orderItems': instance.orderItems,
    };
