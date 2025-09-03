import 'package:leami_desktop/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reservation.g.dart';

@JsonSerializable()
class Reservation {
  int reservationId;
  int userId;
  String reservationDate;
  String reservationTime;

  int numberOfGuests;
  int reservationStatus;
  String? reservationReason;
  int? numberOfMinors;
  String contactPhone;
  String? specialRequests;

  User? user;

  Reservation({
    this.reservationId = 0,
    this.userId = 0,
    this.reservationDate = "",
    this.reservationTime = "",
    this.numberOfGuests = 0,
    this.reservationStatus = 0,
    this.reservationReason = "",
    this.numberOfMinors = 0,
    this.contactPhone = "",
    this.specialRequests = "",
    this.user,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
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
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => _$ReservationToJson(this);
}
