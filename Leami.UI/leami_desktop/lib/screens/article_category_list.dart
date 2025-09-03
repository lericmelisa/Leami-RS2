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
        _error = "Greška pri učitavanju: \$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final list = _categories?.items ?? [];
    return Column(
      children: [
        // search + buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pretraži po nazivu kategorije',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _onSearch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text('Pretraga'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
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

                label: const Text('Dodaj'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // no categories placeholder
        if (list.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'Nema dostupnih kategorija.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          )
        else
          // table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blueAccent,
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
                                    color: Colors.redAccent,
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
          ),
      ],
    );
  }

  void _onSearch() {
    _loadCategories({'FTS': _searchController.text.trim()});
    _searchController.clear();
  }

  void _confirmDelete(ArticleCategory c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brisanje kategorije'),
        content: Text('Obrisati "\${c.categoryName}"?'),
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
                await _loadCategories();
              } catch (e) {
                // error handling
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Ne možete izbrisati'),
                    content: const Text(
                      'Kategorija sadrži artikle. Molimo prvo izbrišite ili premjestite artikle iz ove kategorije.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Izbriši'),
          ),
        ],
      ),
    );
  }
}
