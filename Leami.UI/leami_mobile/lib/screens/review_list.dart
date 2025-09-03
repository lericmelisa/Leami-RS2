import 'package:flutter/material.dart';
import 'package:leami_mobile/models/review.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/providers/review_provider.dart';
import 'package:provider/provider.dart';

class ReviewListScreen extends StatefulWidget {
  const ReviewListScreen({super.key});

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  late ReviewProvider _provider;
  SearchResult<Review>? _reviews;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<ReviewProvider>();
      _loadReviews();
    });
  }

  Future<void> _loadReviews([Map<String, dynamic>? filter]) async {
    setState(() => _isLoading = true);
    try {
      _reviews = await _provider.get(filter: filter);
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Greška pri učitavanju: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final list = _reviews?.items ?? [];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Upravljanje recenzijama'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearch(),
            const SizedBox(height: 16),
            Expanded(child: _buildTable(list)),
          ],
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
            decoration: const InputDecoration(
              hintText: 'Pretražite po datumu ili imenu i prezimenu korisnika',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _loadReviews({"FTS": _searchController.text}),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _loadReviews({"FTS": _searchController.text}),
          child: const Text('Pretraži'),
        ),
      ],
    );
  }

  Widget _buildTable(List<Review> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Nema recenzija.'));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Korisnik')),
            DataColumn(label: Text('Ocjena')),
            DataColumn(label: Text('Komentar')),
            DataColumn(label: Text('Datum')),
            DataColumn(label: Text('Izbrisano')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: list.map((r) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${r.reviewerUser?.firstName ?? '-'} ${r.reviewerUser?.lastName ?? ''}'
                        .trim(),
                  ),
                ),
                DataCell(Text('${r.rating ?? '-'}')),
                DataCell(SizedBox(width: 200, child: Text(r.comment ?? '-'))),
                DataCell(
                  Text(r.createdAt?.toIso8601String().split('T').first ?? '-'),
                ),
                DataCell(Text(r.isDeleted == true ? 'Da' : 'Ne')),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(r),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmDelete(Review r) {
    final TextEditingController _reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brisanje recenzije'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Obrisati recenziju korisnika ${r.reviewerUser?.username}?'),
            TextField(
              controller: _reasonCtrl,
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
                deletionReason: _reasonCtrl.text,
              );
              await _loadReviews({"FTS": _searchController.text});
            },
            child: const Text('Izbriši'),
          ),
        ],
      ),
    );
  }
}
