import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:leami_mobile/screens/guest_user_screen.dart';
import 'package:leami_mobile/screens/login_page.dart';
import 'package:leami_mobile/screens/orders_history_screen.dart';
import 'package:leami_mobile/screens/reservations_list.dart';
import 'package:leami_mobile/screens/restaurant_info_screen.dart';
import 'package:provider/provider.dart';
import 'package:leami_mobile/providers/auth_provider.dart';
import 'package:leami_mobile/providers/cart_provider.dart';
import 'package:leami_mobile/providers/article_provider.dart';
import 'package:leami_mobile/providers/article_category_provider.dart';
import 'package:leami_mobile/models/article.dart';
import 'package:leami_mobile/models/article_category.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/screens/cart_screen.dart';

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

  int _catPage = 0;

  // Ukupan broj čipova po “stranici” (na prvoj “Sve” + 2 kategorije; dalje po 3 kategorije)
  static const int _catsPerPage = 3;

  // >>> PAGING NAD KATEGORIJAMA – “Sve” zauzima 1 slot na prvoj stranici <<<
  List<ArticleCategory> get _pagedCats {
    const int page0Count = _catsPerPage - 1; // jer "Sve" je 1 slot
    if (_categories.isEmpty) return const [];

    if (_catPage == 0) {
      final take = page0Count.clamp(0, _categories.length);
      return _categories.take(take).toList();
    } else {
      final start = page0Count + (_catPage - 1) * _catsPerPage;
      return _categories.skip(start).take(_catsPerPage).toList();
    }
  }

  bool get _hasPrev => _catPage > 0;

  bool get _hasNext {
    if (_categories.isEmpty) return false;
    const int page0Count = _catsPerPage - 1;
    final remaining = (_categories.length - page0Count).clamp(
      0,
      _categories.length,
    );
    final extraPages = (remaining / _catsPerPage).ceil();
    final totalPages = remaining > 0 ? 1 + extraPages : 1;
    return _catPage < totalPages - 1;
  }

  void _prevCatsPage() {
    if (_hasPrev) setState(() => _catPage--);
  }

  void _nextCatsPage() {
    if (_hasNext) setState(() => _catPage++);
  }

  bool _loading = true;
  String? _error;

  int? _selectedCategoryId;
  final _searchCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _articleProvider = context.read<ArticleProvider>();
    _categoryProvider = context.read<ArticleCategoryProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _load();
    });
  }

  @override
  void dispose() {
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
        _catPage = 0;
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

  Future<void> _logout() async {
    final cart = context.read<CartProvider>();
    final art = context.read<ArticleProvider>();
    final cats = context.read<ArticleCategoryProvider>();

    try {
      (cart as dynamic).clear();
    } catch (_) {}
    try {
      (art as dynamic).clear();
    } catch (_) {}
    try {
      (cats as dynamic).clear();
    } catch (_) {}

    await AuthProvider.logoutApi();
    AuthProvider.logout();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartCount = cart.totalItems;

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
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (cartCount >= 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Korpa',
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        cartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              cursorColor: Theme.of(context).colorScheme.primary,
              onChanged: (_) => setState(() {}),
              // VAŽNO: ne postavljamo filled/fillColor/border ovdje,
              // nego puštamo da naslijedi AppTheme.inputDecorationTheme
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
                // ništa drugo ne override-amo
              ),
              style: const TextStyle(color: Colors.white),
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
                      height: 88,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const arrowWidth = 40.0;
                          const sep = 8.0;
                          final available =
                              constraints.maxWidth -
                              (arrowWidth * 2) -
                              (sep * 2);
                          final perChip = ((available - (sep * 2)) / 3).clamp(
                            72.0,
                            140.0,
                          );

                          return Row(
                            children: [
                              SizedBox(
                                width: arrowWidth,
                                child: IconButton(
                                  tooltip: 'Prethodne',
                                  onPressed: _hasPrev ? _prevCatsPage : null,
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 18,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: sep,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      (_catPage == 0 ? 1 : 0) +
                                      _pagedCats.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: sep),
                                  itemBuilder: (_, i) {
                                    if (_catPage == 0 && i == 0) {
                                      return _CategoryChip(
                                        label: 'Sve',
                                        selected: _selectedCategoryId == null,
                                        width: perChip,
                                        onTap: () => setState(
                                          () => _selectedCategoryId = null,
                                        ),
                                      );
                                    }
                                    final idx = _catPage == 0 ? i - 1 : i;
                                    final c = _pagedCats[idx];
                                    final sel =
                                        c.categoryId == _selectedCategoryId;

                                    return _CategoryChip(
                                      label: c.categoryName ?? 'Kategorija',
                                      selected: sel,
                                      width: perChip,
                                      onTap: () => setState(() {
                                        _selectedCategoryId = sel
                                            ? null
                                            : c.categoryId;
                                      }),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                width: arrowWidth,
                                child: IconButton(
                                  tooltip: 'Sljedeće',
                                  onPressed: _hasNext ? _nextCatsPage : null,
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Korisnički profil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GuestUserScreen(userId: AuthProvider.user!.id),
                ),
              ).then((_) => _load());
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: const Text('Rezervacije'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReservationList(userId: AuthProvider.user?.id),
                ),
              ).then((_) => _load());
            },
          ),

          // ── NOVO: Narudžbe ──────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Narudžbe'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OrderHistoryScreen(userId: AuthProvider.user!.id),
                ),
              ).then((_) => _load());
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('O restoranu'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RestaurantInfoListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Odjava'),
            onTap: () async {
              Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
              await _logout();
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
  final double width;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withOpacity(.12)
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(.18),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? Icons.category : Icons.category_outlined,
                  size: 18,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
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
  Future<void> _showRecommendationsDialog(BuildContext context) async {
    try {
      final prov = context.read<ArticleProvider>();

      // Uhvati ID iz modela (kao i u ostatku koda)
      final m = article.toJson() as Map<String, dynamic>;
      final id = m['articleId'] ?? m['id'];
      if (id == null) {
        // Ako nema ID, nema ni preporuka
        print('Rec ID = $id');
        await showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Preporuke'),
            content: Text('Nema dostupnih preporuka.'),
          ),
        );
        return;
      }

      // Fetch preporuka
      print('Rec ID = $id');
      final res = await prov.getRecommended(id as int);
      final items = res.items ?? [];

      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Preporuke'),
            content: items.isEmpty
                ? const Text('Trenutno nemamo jela za preporučiti.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((a) {
                      final mm = a.toJson() as Map<String, dynamic>;
                      final name =
                          (mm['name'] ?? mm['title'] ?? mm['articleName'])
                              as String? ??
                          'Artikal';
                      final price =
                          double.tryParse(
                            '${mm['articlePrice'] ?? mm['unitPrice'] ?? mm['amount']}'
                                .toString()
                                .replaceAll(',', '.'),
                          ) ??
                          0.0;
                      return ListTile(
                        dense: true,
                        title: Text(name),
                        subtitle: price > 0
                            ? Text('${price.toStringAsFixed(2)} KM')
                            : null,
                      );
                    }).toList(),
                  ),
            actions: [
              TextButton(
                child: const Text('Zatvori'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          );
        },
      );
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Preporuke'),
          content: Text('Greška pri učitavanju preporuka: $e'),
          actions: [
            TextButton(
              child: const Text('U redu'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

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
          // ⇩⇩⇩ klik na karticu otvara popup sa detaljima
          onTap: () => _showDetailsDialog(context, name, desc, price, img),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        children: [
                          // Lijevo: cijena
                          Text(
                            '${price.toStringAsFixed(2)} KM',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Desno: dugmad – do kraja reda, bez overflowa
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                alignment: WrapAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.info_outline,
                                      size: 18,
                                    ),
                                    label: const Text('Vidi preporuke'),
                                    onPressed: () =>
                                        _showRecommendationsDialog(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      minimumSize: const Size(0, 36),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: price > 0 ? onAdd : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      minimumSize: const Size(0, 36),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Dodaj'),
                                  ),
                                ],
                              ),
                            ),
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

  // ====== POPUP ======
  void _showDetailsDialog(
    BuildContext context,
    String name,
    String desc,
    double price,
    Uint8List? img,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 140,
                          height: 140,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(.35),
                          child: img != null
                              ? Image.memory(
                                  img,
                                  fit: BoxFit.cover, // isto kao u listi
                                )
                              : const Center(
                                  child: Icon(Icons.image, size: 40),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          desc,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Cijena: ${price.toStringAsFixed(2)} KM',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Samo jedno dugme: Zatvori (full-width)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Zatvori'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // X u gornjem desnom uglu
              Positioned(
                right: 6,
                top: 6,
                child: IconButton(
                  tooltip: 'Zatvori',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        );
      },
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
