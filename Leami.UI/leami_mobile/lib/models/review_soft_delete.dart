import 'package:json_annotation/json_annotation.dart';

part 'review_soft_delete.g.dart';

@JsonSerializable()
class ReviewSoftDeleteRequest {
  final int reviewId;
  final String? deletionReason;

  ReviewSoftDeleteRequest({required this.reviewId, this.deletionReason});

  factory ReviewSoftDeleteRequest.fromJson(Map<String, dynamic> json) =>
      _$ReviewSoftDeleteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewSoftDeleteRequestToJson(this);
}
