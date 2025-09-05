import 'dart:async';
import 'package:flutter/material.dart';
import 'package:leami_desktop/models/reservation.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/providers/reservation_provider.dart';
import 'package:provider/provider.dart';

class EmployeeReservationsScreen extends StatefulWidget {
  const EmployeeReservationsScreen({super.key});

  @override
  State<EmployeeReservationsScreen> createState() =>
      _EmployeeReservationsScreenState();
}

class _EmployeeReservationsScreenState
    extends State<EmployeeReservationsScreen> {
  late ReservationProvider _reservationProvider;
  SearchResult<Reservation>? _reservations;

  final _vCtrl = ScrollController();
  final _hCtrl = ScrollController();

  bool _loading = true;
  String? _error;
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reservationProvider = context.read<ReservationProvider>();
      _loadReservations({"IsExpired": false, "ReservationStatus": 1});
    });
  }

  @override
  void dispose() {
    _vCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReservations([Map<String, dynamic>? filter]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Backend filter (ako ga ima)…
      final res = await _reservationProvider.get(filter: filter);

      // …i sigurnosno filtriranje na klijentu: samo potvrđene (1)
      final onlyApproved = (res.items ?? const <Reservation>[])
          .where((r) => r.reservationStatus == 1)
          .toList();

      _reservations = SearchResult<Reservation>(items: onlyApproved);
    } catch (e) {
      _error = "Greška pri učitavanju rezervacija: $e";
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rezervacije (zaposlenik)')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _showActive = true);
                        _loadReservations({
                          "IsExpired": false,
                          "ReservationStatus": 1,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showActive
                            ? Colors.orange
                            : theme.colorScheme.surfaceVariant,
                        foregroundColor: _showActive ? Colors.white : null,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text('Aktivne'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _showActive = false);
                        _loadReservations({
                          "IsExpired": true,
                          "ReservationStatus": 1,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_showActive
                            ? Colors.orange
                            : theme.colorScheme.surfaceVariant,
                        foregroundColor: !_showActive ? Colors.white : null,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text('Istekle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Osvježi',
                    onPressed: () => _loadReservations({
                      "IsExpired": !_showActive,
                      "ReservationStatus": 1,
                    }),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildTable()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    final list = _reservations?.items ?? const <Reservation>[];
    if (list.isEmpty) {
      return const Center(child: Text("Nema rezervacija za prikaz."));
    }

    // Datum(140) | Vrijeme(120) | Osobe(80) | Korisnik(160) | Telefon(160) | Zahtjevi(420) | Status(120)
    const double contentMinWidth = 140 + 120 + 80 + 160 + 160 + 420 + 120;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        final needsHScroll = contentMinWidth > viewportW;
        final tableWidth = needsHScroll ? contentMinWidth : viewportW;

        final columns = const [
          DataColumn(label: Text('Datum')),
          DataColumn(label: Text('Vrijeme')),
          DataColumn(label: Text('Broj osoba')),
          DataColumn(label: Text('Korisnik')),
          DataColumn(label: Text('Kontakt tel.')),
          DataColumn(label: Text('Specijalni zahtjevi')),
          DataColumn(label: Text('Status')),
        ];

        final rows = list.map((r) {
          return DataRow(
            cells: [
              DataCell(_cell(r.reservationDate ?? '-', maxW: 140)),
              DataCell(_cell(r.reservationTime ?? '-', maxW: 120)),
              DataCell(
                _cell('${r.numberOfGuests ?? '-'}', maxW: 80, center: true),
              ),
              DataCell(_cell('Korisnik #${r.userId ?? '-'}', maxW: 160)),
              DataCell(_cell(r.contactPhone ?? '-', maxW: 160)),
              DataCell(_cell(r.specialRequests ?? '-', maxW: 420)),
              DataCell(
                SizedBox(
                  width: 120,
                  child: _statusChip('Odobreno'), // samo potvrđene se prikazuju
                ),
              ),
            ],
          );
        }).toList();

        final table = SizedBox(
          width: tableWidth,
          child: SingleChildScrollView(
            controller: _vCtrl,
            scrollDirection: Axis.vertical,
            primary: false,
            child: DataTable(
              columnSpacing: 18,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 56,
              headingRowHeight: 48,
              showCheckboxColumn: false,
              columns: columns,
              rows: rows,
            ),
          ),
        );

        return Card(
          child: needsHScroll
              ? Scrollbar(
                  controller: _hCtrl,
                  thumbVisibility: true,
                  interactive: true,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _hCtrl,
                    scrollDirection: Axis.horizontal,
                    primary: false,
                    child: table,
                  ),
                )
              : table,
        );
      },
    );
  }

  Widget _cell(String text, {required double maxW, bool center = false}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        textAlign: center ? TextAlign.center : TextAlign.start,
      ),
    );
  }

  Widget _statusChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
