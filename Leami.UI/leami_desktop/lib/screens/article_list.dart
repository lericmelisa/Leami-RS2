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

class _ArticleListState extends State<ArticleList>
    with SingleTickerProviderStateMixin {
  late ArticleProvider articleProvider;
  late ArticleCategoryProvider articleCategoryProvider;
  TabController? _tabController;

  SearchResult<Article>? articles;
  SearchResult<ArticleCategory>? categories;

  final TextEditingController searchController = TextEditingController();
  int selectedIndex = 0;
  int? highlightedArticleId;

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
    final length = categories?.items?.length ?? 0;
    if (length > 0) {
      _tabController = TabController(length: length, vsync: this);
      selectedIndex = 0;
    }
    setState(() {});
  }

  Future<void> _loadCategories() async {
    try {
      categories = await articleCategoryProvider.get();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadArticles() async {
    try {
      articles = await articleProvider.get();
    } catch (e) {
      debugPrint('Error loading articles: $e');
    }
  }

  Future<void> _performSearch(String term) async {
    final trimmed = term.trim().toLowerCase();
    if (trimmed.isEmpty) {
      setState(() => highlightedArticleId = null);
      return;
    }
    Article? match;
    for (var a in articles?.items ?? []) {
      if (a.articleName?.toLowerCase().contains(trimmed) ?? false) {
        match = a;
        break;
      }
    }
    if (match != null && _tabController != null) {
      final catIndex = categories!.items!.indexWhere(
        (c) => c.categoryId == match?.categoryId,
      );
      if (catIndex != -1) {
        highlightedArticleId = match.articleId;
        _tabController!.index = catIndex;
        setState(() => selectedIndex = catIndex);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchController.clear();
        });
      }
    }
  }

  List<Article> _filterItemsForCategory(int catId) {
    return (articles?.items ?? []).where((a) => a.categoryId == catId).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null || categories == null) {
      return const Center(
        child: Text(
          'Nema dostupnih kategorija, te zbog toga ne možete dodati artikle. Prvo dodaje kategoriju, pa će dodavanje artikala biti omogućeno.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    final catList = categories!.items!;
    if (catList.isEmpty) {
      return const Center(
        child: Text(
          'Nema dostupnih kategorija niti artikala.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    return Column(
      children: [
        _buildSearch(),
        const SizedBox(height: 8),
        Expanded(child: _buildResultView(catList)),
      ],
    );
  }

  Widget _buildSearch() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Pretražite artikle po nazivu',
            ),
            onSubmitted: (_) => _performSearch(searchController.text),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _performSearch(searchController.text),
          child: const Text('Pretraga'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            final res = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const ArticleDetailsScreen(article: null),
              ),
            );
            if (res == true) {
              await _loadArticles();
              setState(() {});
            }
          },
          child: const Text('Dodaj'),
        ),
      ],
    ),
  );

  Widget _buildResultView(List<ArticleCategory> catList) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.orange,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        indicator: BoxDecoration(borderRadius: BorderRadius.circular(999)),
        indicatorSize: TabBarIndicatorSize.label,
        unselectedLabelColor: Colors.white70,
        tabs: [for (var c in catList) Tab(text: c.categoryName!)],
        onTap: (idx) => setState(() {
          selectedIndex = idx;
          highlightedArticleId = null;
          searchController.clear();
        }),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            for (var i = 0; i < catList.length; i++)
              _CategoryGrid(
                categoryId: catList[i].categoryId!,
                items: _filterItemsForCategory(catList[i].categoryId!),
                highlightedArticleId: (i == selectedIndex)
                    ? highlightedArticleId
                    : null,
                onAddNew: () async {
                  final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ArticleDetailsScreen(article: null),
                    ),
                  );
                  if (res == true) {
                    await _loadArticles();
                    setState(() {});
                  }
                },
                onEdit: (art) async {
                  final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailsScreen(article: art),
                    ),
                  );
                  if (res == true) {
                    await _loadArticles();
                    setState(() {});
                  }
                },
                onDelete: (art) async {
                  await articleProvider.delete(art.articleId!);
                  await _loadArticles();
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    ],
  );
}

class _CategoryGrid extends StatefulWidget {
  final int categoryId;
  final List<Article> items;
  final int? highlightedArticleId;
  final VoidCallback onAddNew;
  final void Function(Article) onEdit;
  final void Function(Article) onDelete;

  const _CategoryGrid({
    Key? key,
    required this.categoryId,
    required this.items,
    required this.onAddNew,
    required this.onEdit,
    required this.onDelete,
    this.highlightedArticleId,
  }) : super(key: key);

  @override
  State<_CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<_CategoryGrid> {
  final ScrollController _scrollController = ScrollController();
  late int crossAxisCount;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CategoryGrid old) {
    super.didUpdateWidget(old);
    if (widget.highlightedArticleId != null) {
      final idx = widget.items.indexWhere(
        (a) => a.articleId == widget.highlightedArticleId,
      );
      if (idx != -1) {
        final gridIndex = idx + 1; // zbog AddCard
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final row = (gridIndex / crossAxisCount).floor();
          const itemHeight = 300.0;
          const spacing = 12.0;
          final offset = row * (itemHeight + spacing);
          _scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, box) {
        crossAxisCount = (box.maxWidth / 280).floor().clamp(
          1,
          (box.maxWidth / 280).floor(),
        );
        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: widget.items.length + 1,
          itemBuilder: (ctx, index) {
            if (index == 0) return _AddCard(onTap: widget.onAddNew);
            final article = widget.items[index - 1];
            final isHighlighted =
                article.articleId == widget.highlightedArticleId;
            return Container(
              decoration: isHighlighted
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: _ArticleCard(
                article: article,
                priceText: formatNumber(article.articlePrice),
                onEdit: () => widget.onEdit(article),
                onDelete: () => widget.onDelete(article),
              ),
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
    Key? key,
    required this.article,
    required this.priceText,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Brisanje artikla'),
                    content: const Text(
                      'Jeste li sigurni da želite izbrisati ovaj artikal?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Odustani'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          onDelete();
                        },
                        child: const Text('Izbriši'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCard({Key? key, required this.onTap}) : super(key: key);

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
  const _BorderCard({Key? key, required this.child}) : super(key: key);

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
