// lib/screens/reservation_news.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:leami_mobile/providers/stomp_provider.dart';
import 'package:leami_mobile/theme/theme.dart';

class ReservationNews extends StatefulWidget {
  const ReservationNews({Key? key}) : super(key: key);

  @override
  State<ReservationNews> createState() => _ReservationNewsState();
}

class _ReservationNewsState extends State<ReservationNews> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StompService>().markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgs = context.watch<StompService>().messages;

    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: const Text('Reservation News'),
          backgroundColor: AppTheme.surface,
        ),
        body: msgs.isEmpty
            ? Center(
                child: Text(
                  'Nema obavijesti',
                  style: TextStyle(
                    color: AppTheme.primary, // ili onPrimary
                    fontSize: 16,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                separatorBuilder: (_, __) => Divider(color: AppTheme.outline),
                itemBuilder: (_, i) {
                  return Card(
                    color: AppTheme.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.outline),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.notifications,
                        color: AppTheme.primary,
                      ),
                      title: Text(
                        msgs[i],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
