import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../models/search_result.dart';
import '../providers/reservation_provider.dart';
import '../providers/auth_provider.dart';
import 'create_reservation_screen.dart';

class ReservationList extends StatefulWidget {
  final int? userId;
  const ReservationList({super.key, this.userId});

  @override
  State<ReservationList> createState() => _ReservationListState();
}

class _ReservationListState extends State<ReservationList> {
  late ReservationProvider reservationProvider;
  SearchResult<Reservation>? reservations;

  final ScrollController _vCtrl = ScrollController();
  final ScrollController _hCtrl = ScrollController();

  bool _isLoading = true;
  String? _error;
  bool _showActive = true;

  int? _effectiveUserId;
  bool _inited = false; // <— guard

  @override
  void dispose() {
    _vCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return; // <— spriječi dupli init
    _inited = true;

    reservationProvider = context.read<ReservationProvider>();
    _effectiveUserId = widget.userId ?? AuthProvider.user?.id;

    _loadReservations({
      if (_effectiveUserId != null) "UserId": _effectiveUserId,
      "IsExpired": false,
    });
  }

  Future<void> _loadReservations([Map<String, dynamic>? filter]) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint("[ReservationList] loading with filter: $filter");
      // ⬇ timeout: spriječi beskonačno čekanje
      reservations = await reservationProvider
          .get(filter: filter)
          .timeout(const Duration(seconds: 15));
      debugPrint(
        "[ReservationList] loaded: ${reservations?.items?.length ?? 0} items",
      );
    } on TimeoutException {
      _error = "Vrijeme čekanja je isteklo. Provjeri konekciju ili API.";
    } catch (e) {
      _error = "Greška prilikom učitavanja rezervacija: $e";
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dok čekaš – prikaži normalan Scaffold s loaderom
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moje rezervacije')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moje rezervacije')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadReservations({
                    if (_effectiveUserId != null) "UserId": _effectiveUserId,
                    "IsExpired": !_showActive,
                  }),
                  child: const Text("Pokušaj ponovo"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Moje rezervacije')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreatePressed,
        icon: const Icon(Icons.add),
        label: const Text("Napravi rezervaciju"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _buildTopButtons(),
              const SizedBox(height: 16),
              Expanded(child: _buildResultView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopButtons() {
    // Paleta
    final Color selectedBg = Colors.orange; // narandžasta za aktivno
    final Color selectedFg = Colors.white; // bijeli tekst na narandžastoj
    final Color unselectedBg = Colors.grey; // siva pozadina za neaktivno
    final Color unselectedFg = Colors.black87; // tamni tekst na sivoj

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (!_showActive) {
                setState(() => _showActive = true);
                _loadReservations({
                  if (_effectiveUserId != null) "UserId": _effectiveUserId,
                  "IsExpired": false,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _showActive ? selectedBg : unselectedBg,
              foregroundColor: _showActive ? selectedFg : unselectedFg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Aktivne"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (_showActive) {
                setState(() => _showActive = false);
                _loadReservations({
                  if (_effectiveUserId != null) "UserId": _effectiveUserId,
                  "IsExpired": true,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: !_showActive ? selectedBg : unselectedBg,
              foregroundColor: !_showActive ? selectedFg : unselectedFg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Historija"),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Osvježi',
          onPressed: () {
            _loadReservations({
              if (_effectiveUserId != null) "UserId": _effectiveUserId,
              "IsExpired": !_showActive,
            });
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final list = reservations?.items ?? const <Reservation>[];
    if (list.isEmpty) {
      return const Center(child: Text("Nema rezervacija za prikaz."));
    }

    final columns = <DataColumn>[
      const DataColumn(label: Text('Datum')),
      const DataColumn(label: Text('Vrijeme')),
      const DataColumn(label: Text('Status')),
      const DataColumn(label: Text('Akcije')),
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _vCtrl,
            child: SingleChildScrollView(
              controller: _vCtrl,
              scrollDirection: Axis.vertical,
              primary: false,
              child: Scrollbar(
                controller: _hCtrl,
                notificationPredicate: (notif) =>
                    notif.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _hCtrl,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: 15,
                      columns: columns,
                      rows: list.map((r) {
                        final DateTime? date = r.reservationDate != null
                            ? DateTime.tryParse(r.reservationDate!)
                            : null;
                        final isExpired = date != null && date.isBefore(today);
                        final statusText = _statusText(
                          r.reservationStatus,
                          isExpired,
                        );

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                r.reservationDate ?? '-',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DataCell(
                              Text(
                                r.reservationTime ?? '-',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            DataCell(_statusChip(statusText)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Detalji',
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () => _openDetails(r),
                                  ),
                                  // Dozvoli otkaz/brisanje samo ako je buduća i nije već istekla
                                  IconButton(
                                    tooltip: 'Otkaži',
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    onPressed: isExpired
                                        ? null
                                        : () => _showCancelDialog(r),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _statusText(int? status, bool expired) {
    if (expired) return 'Isteklo';
    switch (status) {
      case 1:
        return 'Odobreno';
      case 0:
        return 'Odbijeno';
      default:
        return 'Na čekanju';
    }
  }

  Widget _statusChip(String text) {
    Color? bg;
    switch (text) {
      case 'Odobreno':
        bg = Colors.green;
        break;
      case 'Odbijeno':
        bg = Colors.red;
        break;
      case 'Isteklo':
        bg = Colors.grey.shade300;
        break;
      default:
        bg = const Color.fromARGB(255, 66, 59, 37); // Na čekanju
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _onCreatePressed() async {
    // Navigacija na novi ekran za kreiranje rezervacije.
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateReservationScreen()),
    );

    // Ako je nešto kreirano, osvježi listu
    if (created == true) {
      await _loadReservations({
        if (_effectiveUserId != null) "UserId": _effectiveUserId,
        "IsExpired": !_showActive,
      });
    }
  }

  void _openDetails(Reservation r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
        title: Row(
          children: [
            const Expanded(child: Text('Detalji rezervacije')),
            IconButton(
              tooltip: 'Zatvori',
              splashRadius: 18,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Datum: ${r.reservationDate ?? "-"}'),
            Text('Vrijeme: ${r.reservationTime ?? "-"}'),
            Text('Broj osoba: ${r.numberOfGuests ?? "-"}'),
            Text('Telefon: ${r.contactPhone ?? "-"}'),
            Text('Zahtjevi:${r.specialRequests ?? "-"}'),
            Text('Broj djece:${r.numberOfMinors ?? "-"}'),
            Text('Razlog rezervacije:${r.reservationReason ?? "-"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Reservation r) {
    if (r.reservationId == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Otkazivanje rezervacije"),
        content: const Text("Da li želite otkazati ovu rezervaciju?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Ne"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await reservationProvider.delete(r.reservationId!);
                await _loadReservations({
                  if (_effectiveUserId != null) "UserId": _effectiveUserId,
                  "IsExpired": !_showActive,
                });
              } catch (e) {
                _showError("Greška prilikom otkazivanja: $e");
              }
            },
            child: const Text("Da, otkaži"),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Greška"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Ok"),
          ),
        ],
      ),
    );
  }
}
