import 'package:leami_mobile/models/reservation.dart';
import 'package:leami_mobile/providers/base_provider.dart';

class ReservationProvider extends BaseProvider<Reservation> {
  ReservationProvider() : super("Reservation");

  @override
  Reservation fromJson(dynamic json) {
    return Reservation.fromJson(json);
  }
}
