import 'package:leami_mobile/models/restaurant_info.dart';
import 'package:leami_mobile/providers/base_provider.dart';

class RestaurantInfoProvider extends BaseProvider<RestaurantInfo> {
  RestaurantInfoProvider() : super("RestaurantInfo");

  @override
  RestaurantInfo fromJson(data) =>
      RestaurantInfo.fromJson(data as Map<String, dynamic>);

  Future<RestaurantInfo> getInfo() async {
    final result = await get();
    final items = result.items;

    if (items == null || items.isEmpty) {
      throw Exception("Nema postavki restorana u bazi.");
    }

    // Inače vrati prvi (i jedini) element
    return items.first;
  }
}
