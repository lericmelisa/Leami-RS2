import 'package:json_annotation/json_annotation.dart';
import 'package:leami_desktop/models/article.dart';
part 'order_item_response.g.dart';

@JsonSerializable()
class OrderItemResponse {
  final int orderItemId;
  final int articleId;
  final int quantity;
  final double unitPrice;
  final double total;
  final Article article;
  OrderItemResponse({
    required this.orderItemId,
    required this.articleId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.article,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderItemResponseFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemResponseToJson(this);
}
