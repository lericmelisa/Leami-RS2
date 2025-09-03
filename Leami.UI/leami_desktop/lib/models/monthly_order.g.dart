// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthlyOrderData _$MonthlyOrderDataFromJson(Map<String, dynamic> json) =>
    MonthlyOrderData(
      month: json['month'] == null
          ? null
          : DateTime.parse(json['month'] as String),
      totalCount: (json['totalCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MonthlyOrderDataToJson(MonthlyOrderData instance) =>
    <String, dynamic>{
      'month': instance.month.toIso8601String(),
      'totalCount': instance.totalCount,
    };
