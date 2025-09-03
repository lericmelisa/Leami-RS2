import 'package:json_annotation/json_annotation.dart';
part 'monthly_revenue.g.dart';

@JsonSerializable()
class MonthlyRevenueData {
  final DateTime month;
  final double totalRevenue;

  MonthlyRevenueData({DateTime? month, double? totalRevenue})
    : month = month ?? DateTime.now(),
      totalRevenue = totalRevenue ?? 0.0;

  factory MonthlyRevenueData.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueData(
      month: json['month'] != null
          ? DateTime.tryParse(json['month'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Safe getters
  DateTime get safeMonth => month;
  double get safeRevenue => totalRevenue;
  int get safeCount => totalRevenue.round(); // For chart compatibility

  factory MonthlyRevenueData.fromJsonOld(Map<String, dynamic> json) =>
      _$MonthlyRevenueDataFromJson(json);
}
