import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../models/search_result.dart';
import '../providers/reservation_provider.dart';

class ReservationList extends StatefulWidget {
  const ReservationList({super.key});

  @override
  State<ReservationList> createState() => _ReservationListState();
}

class _ReservationListState extends State<ReservationList> {
  late ReservationProvider reservationProvider;
  SearchResult<Reservation>? reservations;

  final TextEditingController searchController = TextEditingController();

  final ScrollController _vCtrl = ScrollController(); // vertical
  final ScrollController _hCtrl = ScrollController(); // horizontal

  bool _isLoading = true;
  String? _error;

  bool _showActive = true;

  @override
  void dispose() {
    _vCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reservationProvider = context.read<ReservationProvider>();
      _loadReservations();
    });
  }

  Future<void> _loadReservations([Map<String, dynamic>? filter]) async {
    try {
      setState(() => _isLoading = true);
      reservations = await reservationProvider.get(filter: filter);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = "Greška prilikom učitavanja rezervacija: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
    return Row(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _showActive
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          onPressed: () {
            setState(() => _showActive = true);
            // Aktivne = isExpired = false
            _loadReservations({"IsExpired": false});
          },
          child: const Text("Aktivne"),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: !_showActive
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          onPressed: () {
            setState(() => _showActive = false);
            // Istekle = isExpired = true
            _loadReservations({"IsExpired": true});
          },
          child: const Text("Istekle"),
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
      const DataColumn(label: Text('Datum rezervacije')),
      const DataColumn(label: Text('Vrijeme rezervacije')),
      const DataColumn(label: Text('Broj osoba')),
      const DataColumn(label: Text('Korisnik')),
      const DataColumn(label: Text('Specijalni zahtjevi')),
      const DataColumn(label: Text('Odobri')),
      const DataColumn(label: Text('Akcije')),
    ];

    final now = DateTime.now();

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            thumbVisibility: false,
            controller: _vCtrl,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              primary: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                primary: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 16,
                    columns: columns,
                    rows: list.map((r) {
                      // Parsiraj datum iz stringa
                      DateTime? date = r.reservationDate != null
                          ? DateTime.tryParse(r.reservationDate!)
                          : null;
                      // Ako je datum manji od danas, riječ je o istekloj
                      final isExpired =
                          date != null &&
                          date.isBefore(DateTime(now.year, now.month, now.day));

                      // Disable ako je već odobreno ili isteklo
                      final canApprove = !isExpired && r.reservationStatus != 1;

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
                          DataCell(
                            Text(
                              r.numberOfGuests?.toString() ?? '-',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            Text(
                              r.user?.firstName ?? 'Nepoznat',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            Text(
                              r.specialRequests ?? '-',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            ElevatedButton(
                              onPressed: canApprove
                                  ? () => _showApproveDialog(r)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canApprove
                                    ? (r.reservationStatus == 1
                                          ? Colors.green
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary)
                                    : Colors
                                          .grey, // ili null pa ostavi default disabled
                              ),
                              child: Text(
                                r.reservationStatus == 1
                                    ? 'Odobreno'
                                    : (isExpired ? 'Isteklo' : 'Odobri'),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(r),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showApproveDialog(Reservation r) {
    if (r.reservationStatus == 1) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Odobri rezervaciju"),
        content: const Text(
          "Da li ste sigurni da želite odobriti ovu rezervaciju?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Ne"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _approveReservation(r);
            },
            child: const Text("Da"),
          ),
        ],
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (r.reservationId != null) {
                try {
                  await reservationProvider.delete(r.reservationId!);
                  await _loadReservations();
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

  Future<void> _approveReservation(Reservation r) async {
    if (r.reservationId == null) return;

    final body = {
      "reservationDate": r.reservationDate,
      "reservationTime": r.reservationTime,
      "numberOfGuests": r.numberOfGuests,
      "reservationStatus": 1,
      "userId": r.userId,
      "reservationReason": r.reservationReason,
      "numberOfMinors": r.numberOfMinors,
      "contactPhone": r.contactPhone,
      "specialRequests": r.specialRequests,
    };

    try {
      await reservationProvider.update(r.reservationId!, body);
      await _loadReservations();
    } catch (e) {
      _showError("Greška prilikom odobravanja: $e");
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
