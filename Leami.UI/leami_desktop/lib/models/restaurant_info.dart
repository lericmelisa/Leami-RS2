import 'package:json_annotation/json_annotation.dart';

part 'restaurant_info.g.dart';

@JsonSerializable()
class RestaurantInfo {
  int? restaurantId;
  String name;
  String? description;
  String? address;
  String? phone;
  String? restaurantImage;
  String openingTime;
  String closingTime; // "HH:mm:ss"

  RestaurantInfo({
     this.restaurantId,
    this.name = '',
    this.description,
    this.address,
    this.phone,
    this.restaurantImage,
    this.openingTime = '09:00:00',
    this.closingTime = '17:00:00',
  });

  factory RestaurantInfo.fromJson(Map<String, dynamic> json) =>
      _$RestaurantInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantInfoToJson(this);
}
