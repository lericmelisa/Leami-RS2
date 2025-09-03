import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:leami_mobile/models/article.dart';
import 'package:leami_mobile/models/article_category.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/providers/article_category_provider.dart';
import 'package:leami_mobile/providers/article_provider.dart';
import 'package:leami_mobile/providers/utils.dart';
import 'package:leami_mobile/screens/article_details_screen.dart';
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

  Future<void> _loadArticles([Map<String, dynamic>? filter]) async {
    try {
      articles = await articleProvider.get(filter: filter);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading articles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
            Expanded(child: _buildResultView()),
          ],
        ),
      ),
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
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () =>
                _loadArticles({"ArticleName": searchController.text}),
            child: const Text("Pretraga"),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArticleDetailsScreen(article: null),
                ),
              );
              if (result == true) {
                await _loadArticles();
              }
            },
            child: const Text("Dodaj novi"),
          ),
        ],
      ),
    );
  }

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
          _LeamiTabBar(
            tabs: [
              for (final c in catList)
                Tab(text: c.categoryName ?? 'Kategorija'),
            ],
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
                    onAddNew: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ArticleDetailsScreen(article: null),
                        ),
                      );
                      if (result == true) await _loadArticles();
                    },
                    onEdit: (article) async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ArticleDetailsScreen(article: article),
                        ),
                      );
                      if (result == true) await _loadArticles();
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

  void _showDeleteArticleDialog(Article item) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Da li ste sigurni da želite izbrisati artikal?"),
        content: const Text("..."),
        actions: [
          TextButton(
            child: const Text("Odustani"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("Izbriši"),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (item.articleId != null) {
                await articleProvider.delete(item.articleId!);
                await _loadArticles();
              }
            },
          ),
        ],
      ),
    );
  }
}

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
      builder: (ctx, box) {
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
          itemCount: items.length + 1,
          itemBuilder: (ctx, index) {
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
            child: IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.redAccent,
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

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
