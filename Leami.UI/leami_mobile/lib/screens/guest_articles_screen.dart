// lib/screens/guest_articles_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:leami_mobile/providers/notification_provider.dart';
import 'package:leami_mobile/providers/stomp_provider.dart';
import 'package:leami_mobile/screens/reservation_news.dart';
import 'package:provider/provider.dart';

import 'package:leami_mobile/providers/auth_provider.dart';
import 'package:leami_mobile/providers/cart_provider.dart';
import 'package:leami_mobile/providers/article_provider.dart';
import 'package:leami_mobile/providers/article_category_provider.dart';
import 'package:leami_mobile/models/article.dart';
import 'package:leami_mobile/models/article_category.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/screens/cart_screen.dart';
import 'package:leami_mobile/screens/guest_user_screen.dart';

class GuestArticlesScreen extends StatefulWidget {
  const GuestArticlesScreen({super.key});

  @override
  State<GuestArticlesScreen> createState() => _GuestArticlesScreenState();
}

class _GuestArticlesScreenState extends State<GuestArticlesScreen> {
  late ArticleProvider _articleProvider;
  late ArticleCategoryProvider _categoryProvider;

  SearchResult<Article>? _articlesResult;
  List<Article> _allArticles = [];
  List<ArticleCategory> _categories = [];

  bool _loading = true;
  String? _error;

  int? _selectedCategoryId;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _articleProvider = context.read<ArticleProvider>();
      _categoryProvider = context.read<ArticleCategoryProvider>();
      await _load();
      final stompService = context.read<StompService>();
      stompService.connect();
      final notifProvider = context.read<NotificationProvider>();
      final historyResult = await notifProvider.get();
      final historyMessages = (historyResult.items ?? [])
          .map((n) => n.message)
          .toList();

      context.read<StompService>().loadHistory(historyMessages);
    });
  }

  @override
  void dispose() {
    context.read<StompService>().disconnect();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await _categoryProvider.get();
      final articles = await _articleProvider.get();
      setState(() {
        _categories = cats.items ?? [];
        _articlesResult = articles;
        _allArticles = articles.items ?? [];
      });
    } catch (e) {
      setState(() => _error = 'Greška pri učitavanju: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Article> get _filtered {
    var list = _allArticles;
    if (_selectedCategoryId != null) {
      list = list.where((a) {
        final m = a.toJson() as Map<String, dynamic>;
        final catId = m['articleCategoryId'] ?? m['categoryId'];
        return catId == _selectedCategoryId;
      }).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((a) {
        final name =
            _readStr(a, ['name', 'title', 'articleName'])?.toLowerCase() ?? '';
        final desc =
            _readStr(a, ['description', 'articleDescription'])?.toLowerCase() ??
            '';
        return name.contains(q) || desc.contains(q);
      }).toList();
    }
    return list;
  }

  void _showAddedToCartSnackBar(String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName je dodato u korpu'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: _buildSideMenu(),
      appBar: AppBar(
        title: const Text('Leami'),
        leading: Builder(
          builder: (context) {
            return Consumer<StompService>(
              builder: (_, stomp, __) {
                final count = stomp.unreadCount;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    if (count > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CircleAvatar(
                          radius: 6,
                          backgroundColor: Colors.red,
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Pretraži artikle...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _filtered.isEmpty && _searchCtrl.text.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text('Nema rezultata pretrage'),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (_categories.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Kategorije',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return _CategoryChip(
                              label: 'Sve',
                              selected: _selectedCategoryId == null,
                              onTap: () =>
                                  setState(() => _selectedCategoryId = null),
                            );
                          }
                          final c = _categories[i - 1];
                          final sel = c.categoryId == _selectedCategoryId;
                          return _CategoryChip(
                            label: c.categoryName ?? 'Kategorija',
                            selected: sel,
                            onTap: () => setState(() {
                              _selectedCategoryId = sel ? null : c.categoryId;
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      _selectedCategoryId == null
                          ? 'Svi artikli (${_filtered.length})'
                          : 'Artikli (${_filtered.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ..._filtered.map(
                    (article) => _ArticleCard(
                      article: article,
                      onAdd: () {
                        final m = article.toJson() as Map<String, dynamic>;
                        final id = m['articleId'] ?? m['id'];
                        final name =
                            (m['name'] ?? m['title'] ?? m['articleName'])
                                as String? ??
                            'Artikal';
                        final price =
                            double.tryParse(
                              '${m['articlePrice'] ?? m['unitPrice'] ?? m['amount']}'
                                  .toString()
                                  .replaceAll(',', '.'),
                            ) ??
                            0.0;
                        if (id != null && price > 0) {
                          context.read<CartProvider>().addItem(id, name, price);
                          _showAddedToCartSnackBar(name);
                        }
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSideMenu() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.store, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Leami',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Dobrodošli',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Početna'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Artikli'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Korpa'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Obavijesti'),
            trailing: Consumer<StompService>(
              builder: (_, stomp, __) {
                final count = stomp.unreadCount;
                if (count > 0) {
                  return CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReservationNews()),
              ).then((_) {
                // Kad se korisnik vrati, resetuj brojač
                context.read<StompService>().markAllRead();
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Postavke'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuestUserScreen(user: AuthProvider.user),
                ),
              ).then((_) => _load());
            },
          ),
        ],
      ),
    );
  }

  String? _readStr(Article a, List<String> keys) {
    try {
      final m = a.toJson() as Map<String, dynamic>;
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withOpacity(.15)
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? Icons.category : Icons.category_outlined,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onAdd;
  const _ArticleCard({required this.article, required this.onAdd, super.key});

  @override
  Widget build(BuildContext context) {
    final name = _read(['name', 'title', 'articleName']) ?? 'Artikal';
    final desc = _read(['description', 'articleDescription']) ?? 'Nema opisa';
    final price = _readNum(['articlePrice', 'unitPrice', 'amount']) ?? 0.0;
    final img = _decodeImage();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: img != null
                        ? Image.memory(img, fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall!.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${price.toStringAsFixed(2)} KM',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: price > 0 ? onAdd : null,
                            child: const Text('Dodaj'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Uint8List? _decodeImage() {
    try {
      final m = article.toJson() as Map<String, dynamic>;
      for (final k in ['articleImage', 'image', 'photo', 'picture']) {
        final v = m[k];
        if (v is String && v.isNotEmpty) {
          var b64 = v.contains(',') ? v.split(',').last : v;
          return base64Decode(b64);
        }
      }
    } catch (_) {}
    return null;
  }

  String? _read(List<String> keys) {
    try {
      final m = article.toJson() as Map<String, dynamic>;
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  double? _readNum(List<String> keys) {
    try {
      final m = article.toJson() as Map<String, dynamic>;
      for (final k in keys) {
        final v = m[k];
        if (v is num) return v.toDouble();
        if (v is String) {
          final cleaned = v.replaceAll(',', '.');
          return double.tryParse(cleaned);
        }
      }
    } catch (_) {}
    return null;
  }
}
