import 'package:leami_desktop/models/order_response.dart';
import 'package:leami_desktop/providers/base_provider.dart';

class OrderResponseProvider extends BaseProvider<OrderResponse> {
  OrderResponseProvider() : super("Order");

  @override
  OrderResponse fromJson(dynamic json) {
    return OrderResponse.fromJson(json);
  }
}
