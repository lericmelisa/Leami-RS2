// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_revenue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthlyRevenueData _$MonthlyRevenueDataFromJson(Map<String, dynamic> json) =>
    MonthlyRevenueData(
      month: json['month'] == null
          ? null
          : DateTime.parse(json['month'] as String),
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MonthlyRevenueDataToJson(MonthlyRevenueData instance) =>
    <String, dynamic>{
      'month': instance.month.toIso8601String(),
      'totalRevenue': instance.totalRevenue,
    };
