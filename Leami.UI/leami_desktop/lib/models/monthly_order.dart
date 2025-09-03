import 'package:json_annotation/json_annotation.dart';
part 'monthly_order.g.dart';

@JsonSerializable()
class MonthlyOrderData {
  final DateTime month;
  final int totalCount;

  MonthlyOrderData({DateTime? month, int? totalCount})
    : month = month ?? DateTime.now(),
      totalCount = totalCount ?? 0;

  factory MonthlyOrderData.fromJson(Map<String, dynamic> json) {
    return MonthlyOrderData(
      month: json['month'] != null
          ? DateTime.tryParse(json['month'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    );
  }

  // Safe getters
  DateTime get safeMonth => month;
  int get safeCount => totalCount;

  factory MonthlyOrderData.fromJsonOld(Map<String, dynamic> json) =>
      _$MonthlyOrderDataFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyOrderDataToJson(this);
}
