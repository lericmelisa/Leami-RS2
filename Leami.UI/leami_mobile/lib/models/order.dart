import 'package:json_annotation/json_annotation.dart';
import 'package:leami_mobile/models/order_item.dart';

part 'order.g.dart';

@JsonSerializable()
class OrderRequest {
  final int userId;
  final DateTime orderDate;
  final double totalAmount;
  final String paymentMethod;
  final List<OrderItemRequest> items;

  OrderRequest({
    required this.userId,
    required this.orderDate,
    required this.totalAmount,
    required this.paymentMethod,
    required this.items,
  });

  factory OrderRequest.fromJson(Map<String, dynamic> json) =>
      _$OrderRequestFromJson(json);

  // The toJson method will convert an OrderRequest instance to JSON
  Map<String, dynamic> toJson() => _$OrderRequestToJson(this);
}
