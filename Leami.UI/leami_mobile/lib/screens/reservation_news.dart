// lib/screens/reservation_news.dart
import 'package:flutter/material.dart';
import 'package:leami_mobile/theme/theme.dart';

class ReservationNews extends StatelessWidget {
  const ReservationNews({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: const Text('Reservation News'),
          backgroundColor: AppTheme.surface,
        ),
        body: Center(
          child: Text(
            'Nema obavijesti',
            style: TextStyle(color: AppTheme.primary, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
