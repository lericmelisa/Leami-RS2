import 'package:flutter/material.dart';
import 'package:leami_desktop/models/article_category.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/providers/article_category_provider.dart';
import 'package:leami_desktop/screens/article_category_details_screen.dart';
import 'package:provider/provider.dart';

class ArticleCategoryList extends StatefulWidget {
  const ArticleCategoryList({super.key});

  @override
  State<ArticleCategoryList> createState() => _ArticleCategoryListState();
}

class _ArticleCategoryListState extends State<ArticleCategoryList> {
  late ArticleCategoryProvider _provider;
  SearchResult<ArticleCategory>? _categories;

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<ArticleCategoryProvider>();
      _loadCategories();
    });
  }

  Future<void> _loadCategories([Map<String, dynamic>? filter]) async {
    setState(() => _isLoading = true);
    try {
      _categories = await _provider.get(filter: filter);
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Greška pri učitavanju: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final list = _categories?.items ?? [];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearch(),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Naziv')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: list.map((c) {
                      return DataRow(
                        cells: [
                          DataCell(Text(c.categoryName ?? '')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    final result = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ArticleCategoryDetailsScreen(
                                              category: c,
                                            ),
                                      ),
                                    );
                                    if (result == true) _loadCategories();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDelete(c),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const ArticleCategoryDetailsScreen(category: null),
            ),
          );
          if (result == true) _loadCategories();
        },
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
              hintText: 'Pretraži po nazivu kategorije',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) =>
                _loadCategories({"FTS": _searchController.text}),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          child: const Text('Pretraga'),
          onPressed: () => _loadCategories({"FTS": _searchController.text}),
        ),
      ],
    );
  }

  void _confirmDelete(ArticleCategory c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brisanje kategorije'),
        content: Text('Obrisati "${c.categoryName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _provider.delete(c.categoryId!);
                _loadCategories();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Greška: $e')));
              }
            },
            child: const Text('Izbriši'),
          ),
        ],
      ),
    );
  }
}
