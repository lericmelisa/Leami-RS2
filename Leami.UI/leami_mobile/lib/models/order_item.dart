import 'package:json_annotation/json_annotation.dart';

part 'order_item.g.dart';

@JsonSerializable()
class OrderItemRequest {
  final int articleId;
  final int quantity;
  final double unitPrice;

  OrderItemRequest({
    required this.articleId,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemRequest.fromJson(Map<String, dynamic> json) =>
      _$OrderItemRequestFromJson(json);

  // The toJson method will convert an OrderRequest instance to JSON
  Map<String, dynamic> toJson() => _$OrderItemRequestToJson(this);
}
