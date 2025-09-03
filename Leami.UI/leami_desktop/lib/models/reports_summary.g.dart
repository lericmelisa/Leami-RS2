// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportsSummary _$ReportsSummaryFromJson(Map<String, dynamic> json) =>
    ReportsSummary(
      totalUsers: (json['totalUsers'] as num?)?.toInt(),
      totalOrders: (json['totalOrders'] as num?)?.toInt(),
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ReportsSummaryToJson(ReportsSummary instance) =>
    <String, dynamic>{
      'totalUsers': instance.totalUsers,
      'totalOrders': instance.totalOrders,
      'totalRevenue': instance.totalRevenue,
    };
