import 'package:json_annotation/json_annotation.dart';

part 'monthly_count_data.g.dart';

@JsonSerializable()
class MonthlyCountData {
  final DateTime month;
  final int totalCount;
  DateTime get safeMonth => month;
  int get safeCount => totalCount;
  MonthlyCountData({DateTime? month, int? totalCount})
    : month = month ?? DateTime.now(),
      totalCount = totalCount ?? 0;

  factory MonthlyCountData.fromJson(Map<String, dynamic> json) =>
      _$MonthlyCountDataFromJson(json);
}
