import 'package:leami_desktop/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reservation.g.dart';

@JsonSerializable()
class Reservation {
  int? reservationId;
  int? userId;
  String? reservationDate;
  String? reservationTime;

  int? numberOfGuests;
  int? reservationStatus;
  String? reservationReason;
  int? numberOfMinors;
  String? contactPhone;
  String? specialRequests;

  User? user;

  Reservation({
    this.reservationId,
    this.userId,
    this.reservationDate,
    this.reservationTime,

    this.numberOfGuests,
    this.reservationStatus,
    this.reservationReason,
    this.numberOfMinors,
    this.contactPhone,
    this.specialRequests,
    this.user,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) =>
      _$ReservationFromJson(json);
}
