import 'package:leami_mobile/models/order.dart';
import 'package:leami_mobile/providers/base_provider.dart';

class OrderProvider extends BaseProvider<OrderRequest> {
  OrderProvider() : super("Order");

  @override
  OrderRequest fromJson(dynamic json) {
    return OrderRequest.fromJson(json);
  }
}
