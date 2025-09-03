// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_soft_delete.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewSoftDeleteRequest _$ReviewSoftDeleteRequestFromJson(
  Map<String, dynamic> json,
) => ReviewSoftDeleteRequest(
  reviewId: (json['reviewId'] as num).toInt(),
  deletionReason: json['deletionReason'] as String?,
);

Map<String, dynamic> _$ReviewSoftDeleteRequestToJson(
  ReviewSoftDeleteRequest instance,
) => <String, dynamic>{
  'reviewId': instance.reviewId,
  'deletionReason': instance.deletionReason,
};
