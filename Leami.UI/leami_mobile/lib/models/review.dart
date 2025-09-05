import 'package:json_annotation/json_annotation.dart';
import 'package:leami_mobile/models/user.dart';

part 'review.g.dart';

@JsonSerializable(explicitToJson: true)
class Review {
  int reviewId;
  int reviewerUserId;
  int rating;
  String? comment;
  DateTime createdAt;
  User? reviewerUser;
  bool isDeleted;
  String? deletionReason;

  Review({
    this.reviewId = 0,
    this.reviewerUserId = 0,
    this.rating = 0,
    this.comment = "",
    DateTime? createdAt,
    this.reviewerUser,
    this.isDeleted = false,
    this.deletionReason = "",
  }) : createdAt = createdAt ?? DateTime.now();

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}
