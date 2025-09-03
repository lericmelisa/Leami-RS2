// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_count_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthlyCountData _$MonthlyCountDataFromJson(Map<String, dynamic> json) =>
    MonthlyCountData(
      month: json['month'] == null
          ? null
          : DateTime.parse(json['month'] as String),
      totalCount: (json['totalCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MonthlyCountDataToJson(MonthlyCountData instance) =>
    <String, dynamic>{
      'month': instance.month.toIso8601String(),
      'totalCount': instance.totalCount,
    };
