// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reservation _$ReservationFromJson(Map<String, dynamic> json) => Reservation(
  reservationId: (json['reservationId'] as num?)?.toInt() ?? 0,
  userId: (json['userId'] as num?)?.toInt() ?? 0,
  reservationDate: json['reservationDate'] as String? ?? "",
  reservationTime: json['reservationTime'] as String? ?? "",
  numberOfGuests: (json['numberOfGuests'] as num?)?.toInt() ?? 0,
  reservationStatus: (json['reservationStatus'] as num?)?.toInt() ?? 0,
  reservationReason: json['reservationReason'] as String? ?? "",
  numberOfMinors: (json['numberOfMinors'] as num?)?.toInt() ?? 0,
  contactPhone: json['contactPhone'] as String? ?? "",
  specialRequests: json['specialRequests'] as String? ?? "",
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReservationToJson(Reservation instance) =>
    <String, dynamic>{
      'reservationId': instance.reservationId,
      'userId': instance.userId,
      'reservationDate': instance.reservationDate,
      'reservationTime': instance.reservationTime,
      'numberOfGuests': instance.numberOfGuests,
      'reservationStatus': instance.reservationStatus,
      'reservationReason': instance.reservationReason,
      'numberOfMinors': instance.numberOfMinors,
      'contactPhone': instance.contactPhone,
      'specialRequests': instance.specialRequests,
      'user': instance.user,
    };
