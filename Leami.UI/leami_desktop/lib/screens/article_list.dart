import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:leami_desktop/models/article.dart';
import 'package:leami_desktop/models/article_category.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/providers/article_category_provider.dart';
import 'package:leami_desktop/providers/article_provider.dart';
import 'package:leami_desktop/providers/utils.dart';
import 'package:leami_desktop/screens/article_details_screen.dart';
import 'package:provider/provider.dart';

class ArticleList extends StatefulWidget {
  const ArticleList({super.key});

  @override
  State<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<ArticleList> {
  late ArticleProvider articleProvider;
  late ArticleCategoryProvider articleCategoryProvider;

  SearchResult<Article>? articles;
  SearchResult<ArticleCategory>? categories;

  Map<int, ArticleCategory> categoryMap = {};

  final TextEditingController searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    articleProvider = context.read<ArticleProvider>();
    articleCategoryProvider = context.read<ArticleCategoryProvider>();
    _initData();
  }

  Future<void> _initData() async {
    await _loadCategories();
    await _loadArticles();
  }

  Future<void> _loadCategories() async {
    try {
      categories = await articleCategoryProvider.get();
      categoryMap = {
        for (var c in (categories?.items ?? []))
          if (c.categoryId != null) c.categoryId!: c,
      };
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildSearch(),
        const SizedBox(height: 8),
        Expanded(child: _buildResultView()),
      ],
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Pretražite artikle po nazivu',
              ),
              onSubmitted: (_) async {
                await _loadArticles({"ArticleName": searchController.text});
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final filter = {"ArticleName": searchController.text};
              await _loadArticles(filter);
              setState(() {});
            },
            child: const Text("Pretraga"),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailsScreen(article: null),
                ),
              );
            },
            child: const Text("Dodaj novi"),
          ),
        ],
      ),
    );
  }

  /// TabBar (kategorije) + responsivan Grid kartica
  Widget _buildResultView() {
    if (categories == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final catList = categories!.items ?? [];
    if (catList.isEmpty) {
      return const Center(child: Text('Nema dostupnih kategorija.'));
    }

    return DefaultTabController(
      length: catList.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // kontejner iza TabBar-a (tamni panel)
          Container(
            child: _LeamiTabBar(
              tabs: [
                for (final c in catList)
                  Tab(text: c.categoryName ?? 'Kategorija'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                for (final c in catList)
                  _CategoryGrid(
                    categoryId: c.categoryId!,
                    items: (articles?.items ?? [])
                        .where((a) => a.categoryId == c.categoryId)
                        .toList(),
                    onAddNew: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ArticleDetailsScreen(article: null),
                        ),
                      );
                    },
                    onEdit: (article) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ArticleDetailsScreen(article: article),
                        ),
                      );
                    },
                    onDelete: _showDeleteArticleDialog,
                    getCategoryName: (id) =>
                        categoryMap[id]?.categoryName ?? 'N/A',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadArticles([Map<String, dynamic>? filter]) async {
    try {
      articles = await articleProvider.get(filter: filter);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading articles: $e');
    }
  }

  void _showDeleteArticleDialog(Article item) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "Da li ste sigurni da želite izbrisati artikal?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Ako želite izbrisati artikal pritisnite \"Izbriši\"; ako ne, pritisnite \"Odustani\"",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          if (item.articleId == null) {
                            throw Exception("Article id is null");
                          }
                          await articleProvider.delete(item.articleId!);
                          if (mounted) Navigator.of(context).pop();
                          await _loadArticles();
                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                  "Uspješno izbrisan artikal",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      "Uspješno ste izbrisali izabrani artikal!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                ),
                                actions: [
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text("Ok"),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        } catch (e) {
                          if (mounted) Navigator.of(context).pop();
                          _showErrorDialog(
                            "Došlo je do greške prilikom brisanja: $e",
                          );
                        }
                      },
                      child: const Text("Izbriši"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Odustani"),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Greška", textAlign: TextAlign.center),
          content: Text(message),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Ok"),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// TabBar sa "pill" indikatorom (narandžasti za izabranu kategoriju)
class _LeamiTabBar extends StatelessWidget {
  final List<Widget> tabs;
  const _LeamiTabBar({required this.tabs});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      indicator: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      indicatorSize: TabBarIndicatorSize.label,
      unselectedLabelColor: Colors.white70,
      tabs: tabs,
    );
  }
}

/// Grid za jednu kategoriju – responsivan broj kolona i kartice
class _CategoryGrid extends StatelessWidget {
  final int categoryId;
  final List<Article> items;
  final VoidCallback onAddNew;
  final void Function(Article) onEdit;
  final void Function(Article) onDelete;
  final String Function(int) getCategoryName;

  const _CategoryGrid({
    required this.categoryId,
    required this.items,
    required this.onAddNew,
    required this.onEdit,
    required this.onDelete,
    required this.getCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        int crossAxisCount = (box.maxWidth / 280).floor();
        if (crossAxisCount < 1) crossAxisCount = 1;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: items.length + 1, // +1 za "Dodaj novi"
          itemBuilder: (context, index) {
            if (index == 0) {
              return _AddCard(onTap: onAddNew);
            }
            final article = items[index - 1];
            return _ArticleCard(
              article: article,
              priceText: formatNumber(article.articlePrice),
              onEdit: () => onEdit(article),
              onDelete: () => onDelete(article),
            );
          },
        );
      },
    );
  }
}

/// Kartica za artikal
class _ArticleCard extends StatelessWidget {
  final Article article;
  final String priceText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ArticleCard({
    required this.article,
    required this.priceText,
    required this.onEdit,
    required this.onDelete,
  });

  ImageProvider? _imageFromBase64(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(b64));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _imageFromBase64(article.articleImage);

    return Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: img,
                    backgroundColor: const Color(0xFF30374A),
                    child: img == null
                        ? const Icon(
                            Icons.image,
                            size: 36,
                            color: Colors.white70,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  article.articleName ?? 'Bez naziva',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  priceText,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Uredi artikal'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: const ShapeDecoration(
                  color: Color(0x33292F3F), // suptilna tamna pozadina
                  shape: CircleBorder(),
                ),
                child: IconButton(
                  tooltip: 'Izbriši',
                  icon: const Icon(Icons.delete),
                  color: Colors.redAccent,
                  onPressed: onDelete,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartica "Dodaj novi artikal"
class _AddCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: _BorderCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, size: 32, color: Colors.white),
            SizedBox(height: 8),
            Text('Dodaj novi artikal'),
          ],
        ),
      ),
    );
  }
}

/// Jednostavna kartica sa vidljivim rubom (solid border umjesto "tačkica")
class _BorderCard extends StatelessWidget {
  final Widget child;
  const _BorderCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 1.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: child),
    );
  }
}
