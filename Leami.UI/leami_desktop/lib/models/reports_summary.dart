import 'package:json_annotation/json_annotation.dart';

part 'reports_summary.g.dart';

@JsonSerializable()
class ReportsSummary {
  final int totalUsers;
  final int totalOrders;
  final double totalRevenue;

  ReportsSummary({int? totalUsers, int? totalOrders, double? totalRevenue})
    : totalUsers = totalUsers ?? 0,
      totalOrders = totalOrders ?? 0,
      totalRevenue = totalRevenue ?? 0.0;
  int get safeTotalUsers => totalUsers;
  int get safeTotalOrders => totalOrders;
  double get safeTotalRevenue => totalRevenue;
  factory ReportsSummary.fromJson(Map<String, dynamic> json) =>
      _$ReportsSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ReportsSummaryToJson(this);
}
