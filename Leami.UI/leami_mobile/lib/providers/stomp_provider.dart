// lib/providers/stomp_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class StompService with ChangeNotifier {
  StompClient? _client;

  final List<String> _messages = []; // čuva sve poruke
  int _unreadCount = 0; // broji nepročitane

  List<String> get messages => List.unmodifiable(_messages);
  int get unreadCount => _unreadCount;

  void _onMessage(String text) {
    _messages.insert(0, text); // najnovija prva
    _unreadCount++;
    notifyListeners();
  }

  void markAllRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  void loadHistory(List<String> history) {
    _messages.addAll(history);
    notifyListeners();
  }

  void connect() {
    if (_client?.connected ?? false) return;

    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    final wsUrl = 'ws://$host:15674/ws';

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: {
          'login': 'guest',
          'passcode': 'guest',
          'host': '/',
        },
        onConnect: _onConnect,
        beforeConnect: () async {
          debugPrint('Povezujem se na STOMP WS $wsUrl …');
          await Future.delayed(const Duration(milliseconds: 200));
        },
        onWebSocketError: (err) => debugPrint('❌ WS greška: $err'),
        onStompError: (frame) => debugPrint('❌ STOMP greška: ${frame.body}'),
        onDisconnect: (frame) =>
            debugPrint('⚡ STOMP disconnect: ${frame?.body}'),

        heartbeatIncoming: const Duration(seconds: 20),
        heartbeatOutgoing: const Duration(seconds: 20),
      ),
    )..activate();

    debugPrint('✅ STOMP client aktiviran');
  }

  void _onConnect(StompFrame frame) {
    debugPrint('STOMP povezan, pretplata na /queue/reservationQueue');

    _client!.subscribe(
      destination: '/queue/reservationQueue',
      headers: {'ack': 'auto'},
      callback: (frame) {
        String text;

        if (frame.body != null) {
          // standardni tekstualni slučaj
          text = frame.body!;
        } else if (frame.binaryBody != null) {
          // binarni payload: dekodiraj ga u UTF-8
          text = utf8.decode(frame.binaryBody!);
        } else {
          text = '<prazno>';
        }

        print('🛰️ Poruka: $text');

        _onMessage(text);
      },
    );
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    debugPrint('🔌 STOMP disconnected');
  }
}
