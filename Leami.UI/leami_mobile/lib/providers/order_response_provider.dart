import 'package:leami_mobile/models/order_response.dart';
import 'package:leami_mobile/providers/base_provider.dart';

class OrderResponseProvider extends BaseProvider<OrderResponse> {
  OrderResponseProvider() : super("Order");

  @override
  OrderResponse fromJson(dynamic json) {
    return OrderResponse.fromJson(json);
  }
}
