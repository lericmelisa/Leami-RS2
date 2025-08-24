import 'package:json_annotation/json_annotation.dart';
import 'package:leami_desktop/models/user.dart';

part 'review.g.dart';

@JsonSerializable(explicitToJson: true)
class Review {
  int? reviewId;
  int? reviewerUserId;
  int? rating;
  String? comment;
  DateTime? createdAt;
  User? reviewerUser;
  bool? isDeleted;
  String? deletionReason;

  Review({
    this.reviewId,
    this.reviewerUserId,
    this.rating,
    this.comment,
    this.createdAt,
    this.reviewerUser,
    this.isDeleted,
    this.deletionReason,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}