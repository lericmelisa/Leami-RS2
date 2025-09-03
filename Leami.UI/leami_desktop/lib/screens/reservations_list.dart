import 'package:flutter/material.dart';
import 'package:leami_desktop/providers/auth_provider.dart';
import 'package:leami_desktop/models/reservation.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/providers/reservation_provider.dart';
import 'package:provider/provider.dart';

class ReservationList extends StatefulWidget {
  const ReservationList({super.key});

  @override
  State<ReservationList> createState() => _ReservationListState();
}

class _ReservationListState extends State<ReservationList> {
  late ReservationProvider reservationProvider;
  SearchResult<Reservation>? reservations;

  final _vCtrl = ScrollController();
  final _hCtrl = ScrollController();

  bool _isLoading = true;
  String? _error;
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reservationProvider = context.read<ReservationProvider>();
      _loadReservations({"IsExpired": false});
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
      _isLoading = true;
      _error = null;
    });
    try {
      reservations = await reservationProvider.get(filter: filter);
    } catch (e) {
      _error = "Greška pri učitavanju rezervacija: $e";
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return Scaffold(
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
                        _loadReservations({"IsExpired": false});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
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
                        _loadReservations({"IsExpired": true});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_showActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text('Istekle'),
                    ),
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
    final list = reservations?.items ?? const <Reservation>[];
    if (list.isEmpty) {
      return const Center(child: Text("Nema rezervacija za prikaz."));
    }

    // Minimalna širina (zbir širina kolona) da forsiramo horizontalni skrol kad je prozor uzak
    // Datum(140) | Vrijeme(120) | Osobe(80) | Korisnik(200) | Zahtjevi(420) | Status/Approve(160) | Akcije(120)
    const double contentMinWidth = 140 + 120 + 80 + 200 + 420 + 160 + 120;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        final needsHScroll = contentMinWidth > viewportW;
        final tableWidth = needsHScroll ? contentMinWidth : viewportW;

        final columns = const [
          DataColumn(label: Text('Datum rezervacije')),
          DataColumn(label: Text('Vrijeme rezervacije')),
          DataColumn(label: Text('Broj osoba')),
          DataColumn(label: Text('Korisnik')),
          DataColumn(label: Text('Specijalni zahtjevi')),
          DataColumn(label: Text('Odobri')),
          DataColumn(label: Text('Akcije')),
        ];

        final rows = list.map((r) {
          final dateTxt = r.reservationDate ?? '-';
          final timeTxt = r.reservationTime ?? '-';
          final peopleTxt = (r.numberOfGuests?.toString() ?? '-');
          // Ako nemaš korisnika u modelu rezervacije, fallback na trenutnog (kao što si imala):
          final userTxt = (AuthProvider.user?.firstName ?? 'Nepoznat');

          // status: 1=Potvrđeno, 0=Odbijeno, ostalo=Na čekanju
          final isConfirmed = r.reservationStatus == 1;
          final isRejected = r.reservationStatus == 0;
          final isPending = !(isConfirmed || isRejected);

          final approveBtn = ElevatedButton(
            onPressed: isPending ? () => _showDecisionDialog(r) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isConfirmed
                  ? Colors.green
                  : (isRejected
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: Text(
              isConfirmed
                  ? 'Potvrđeno'
                  : (isRejected ? 'Odbijeno' : 'Odobri/Odbij'),
            ),
          );

          return DataRow(
            cells: [
              DataCell(_cell(dateTxt, maxW: 140)),
              DataCell(_cell(timeTxt, maxW: 120)),
              DataCell(_cell(peopleTxt, maxW: 80, center: true)),
              DataCell(_cell(userTxt, maxW: 200)),
              DataCell(_cell(r.specialRequests ?? '-', maxW: 420)),
              DataCell(SizedBox(width: 160, child: approveBtn)),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _showDeleteDialog(r),
                    tooltip: 'Izbriši',
                  ),
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

  // Helper za tekstualnu ćeliju sa max širinom + elipsama
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

  void _showDeleteDialog(Reservation r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Brisanje rezervacije"),
        content: const Text(
          "Da li ste sigurni da želite izbrisati rezervaciju?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (r.reservationId != null) {
                try {
                  await reservationProvider.delete(r.reservationId!);
                  await _loadReservations({"IsExpired": !_showActive});
                } catch (e) {
                  _showError("Greška prilikom brisanja: $e");
                }
              }
            },
            child: const Text("Izbriši"),
          ),
        ],
      ),
    );
  }

  void _showDecisionDialog(Reservation r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Status rezervacije"),
        content: const Text(
          "Da li želite odobriti ili odbiti ovu rezervaciju?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              r.reservationStatus = 0;
              _changeStatus(r);
            },
            child: const Text("Odbij"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              r.reservationStatus = 1;
              _changeStatus(r);
            },
            child: const Text("Potvrdi"),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(Reservation r) async {
    if (r.reservationId == null) return;
    final body = {
      "reservationDate": r.reservationDate,
      "reservationTime": r.reservationTime,
      "numberOfGuests": r.numberOfGuests,
      "reservationStatus": r.reservationStatus,
      "userId": r.userId,
      "reservationReason": r.reservationReason,
      "numberOfMinors": r.numberOfMinors,
      "contactPhone": r.contactPhone,
      "specialRequests": r.specialRequests,
    };

    try {
      await reservationProvider.update(r.reservationId!, body);
      await _loadReservations({"IsExpired": !_showActive});
    } catch (e) {
      _showError("Greška prilikom akcije: $e");
    }
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
