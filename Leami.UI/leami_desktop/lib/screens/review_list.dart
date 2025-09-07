import 'package:flutter/material.dart';
import 'package:leami_desktop/models/review.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/providers/review_provider.dart';
import 'package:provider/provider.dart';

class ReviewListScreen extends StatefulWidget {
  const ReviewListScreen({super.key});

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  late ReviewProvider _provider;
  SearchResult<Review>? _reviews;

  final _hScrollCtrl = ScrollController();
  final _vScrollCtrl = ScrollController();

  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<ReviewProvider>();
      _loadReviews();
    });
  }

  @override
  void dispose() {
    _hScrollCtrl.dispose();
    _vScrollCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews([Map<String, dynamic>? filter]) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _reviews = await _provider.get(filter: filter);
    } catch (e) {
      _error = 'Greška pri učitavanju: $e';
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _doSearch() =>
      _loadReviews({"FTS": _searchController.text.trim()});

  @override
  Widget build(BuildContext context) {
    final list = _reviews?.items ?? [];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearch(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(child: Center(child: Text(_error!)))
              else
                Expanded(child: _buildTable(list)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pretraži po datumu ili imenu/prezimenu',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _doSearch(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: _doSearch, child: const Text('Pretraži')),
      ],
    );
  }

  Widget _buildTable(List<Review> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Nema recenzija.'));
    }

    const double contentMinWidth = 180 + 80 + 420 + 120 + 100 + 120;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        final needsHScroll = contentMinWidth > viewportW;
        final tableWidth = needsHScroll ? contentMinWidth : viewportW;

        final columns = const [
          DataColumn(label: Text('Korisnik')),
          DataColumn(label: Text('Ocjena')),
          DataColumn(label: Text('Komentar')),
          DataColumn(label: Text('Datum')),
          DataColumn(label: Text('Izbrisano')),
          DataColumn(label: Text('Akcije')),
        ];

        final rows = list.map((r) {
          final userName =
              '${r.reviewerUser?.firstName ?? '-'} ${r.reviewerUser?.lastName ?? ''}'
                  .trim();
          final ratingTxt = (r.rating != null)
              ? r.rating!.toStringAsFixed(1)
              : '-';
          final comment = r.comment ?? '-';
          final date = r.createdAt != null
              ? r.createdAt!.toIso8601String().split('T').first
              : '-';
          final deleted = r.isDeleted == true ? 'Da' : 'Ne';

          return DataRow(
            cells: [
              // Korisnik
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    userName,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
              // Ocjena
              const DataCell(SizedBox(width: 80, child: _CenterText())),
              // Komentar
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    comment,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
              // Datum
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    date,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
              // Izbrisano
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    deleted,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
              // Akcije
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Obriši',
                        onPressed: () => _confirmDelete(r),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList();

        for (var i = 0; i < rows.length; i++) {
          final r = list[i];
          final ratingTxt = (r.rating != null)
              ? r.rating!.toStringAsFixed(1)
              : '-';
          rows[i] = DataRow(
            cells: [
              rows[i].cells[0],
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    ratingTxt,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              rows[i].cells[2],
              rows[i].cells[3],
              rows[i].cells[4],
              rows[i].cells[5],
            ],
          );
        }

        final table = SizedBox(
          width: tableWidth,
          child: SingleChildScrollView(
            controller: _vScrollCtrl,
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
                  controller: _hScrollCtrl,
                  thumbVisibility: true,
                  interactive: true,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _hScrollCtrl,
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

  void _confirmDelete(Review r) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brisanje recenzije'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Obrisati recenziju korisnika ${r.reviewerUser?.username}?'),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Razlog brisanja'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _provider.softDelete(
                reviewId: r.reviewId!,
                deletionReason: reasonCtrl.text,
              );
              if (!mounted) return;
              await _loadReviews({"FTS": _searchController.text.trim()});
            },
            child: const Text('Izbriši'),
          ),
        ],
      ),
    );
  }
}

class _CenterText extends StatelessWidget {
  const _CenterText();

  @override
  Widget build(BuildContext context) {
    return const Center(child: SizedBox.shrink());
  }
}
