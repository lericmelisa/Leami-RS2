// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
  reviewId: (json['reviewId'] as num?)?.toInt() ?? 0,
  reviewerUserId: (json['reviewerUserId'] as num?)?.toInt() ?? 0,
  rating: (json['rating'] as num?)?.toInt() ?? 0,
  comment: json['comment'] as String? ?? "",
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  reviewerUser: json['reviewerUser'] == null
      ? null
      : User.fromJson(json['reviewerUser'] as Map<String, dynamic>),
  isDeleted: json['isDeleted'] as bool? ?? false,
  deletionReason: json['deletionReason'] as String? ?? "",
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'reviewId': instance.reviewId,
  'reviewerUserId': instance.reviewerUserId,
  'rating': instance.rating,
  'comment': instance.comment,
  'createdAt': instance.createdAt.toIso8601String(),
  'reviewerUser': instance.reviewerUser?.toJson(),
  'isDeleted': instance.isDeleted,
  'deletionReason': instance.deletionReason,
};
