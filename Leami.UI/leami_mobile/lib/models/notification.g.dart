// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      userId: (json['userId'] as num?)?.toInt(),
      reservationId: (json['reservationId'] as num?)?.toInt(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'reservationId': instance.reservationId,
      'message': instance.message,
    };
