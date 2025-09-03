// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestaurantInfo _$RestaurantInfoFromJson(Map<String, dynamic> json) =>
    RestaurantInfo(
      restaurantId: (json['restaurantId'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      restaurantImage: json['restaurantImage'] as String?,
      openingTime: json['openingTime'] as String? ?? '09:00:00',
      closingTime: json['closingTime'] as String? ?? '17:00:00',
    );

Map<String, dynamic> _$RestaurantInfoToJson(RestaurantInfo instance) =>
    <String, dynamic>{
      'restaurantId': instance.restaurantId,
      'name': instance.name,
      'description': instance.description,
      'address': instance.address,
      'phone': instance.phone,
      'restaurantImage': instance.restaurantImage,
      'openingTime': instance.openingTime,
      'closingTime': instance.closingTime,
    };
