import 'package:leami_mobile/models/order_item_response.dart';
import 'package:json_annotation/json_annotation.dart';
part 'order_response.g.dart';

@JsonSerializable()
class OrderResponse {
  final int orderId;
  final int userId;
  final DateTime orderDate;
  final double totalAmount;
  final String paymentMethod;
  final List<OrderItemResponse> orderItems;

  OrderResponse({
    required this.orderId,
    required this.userId,
    required this.orderDate,
    required this.totalAmount,
    required this.paymentMethod,
    required this.orderItems,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrderResponseToJson(this);
}
