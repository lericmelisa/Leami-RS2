import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:leami_mobile/models/article.dart'; // <-- prilagodi import
import 'package:leami_mobile/models/search_result.dart'; // <-- prilagodi import
import 'package:leami_mobile/providers/article_provider.dart'; // <-- prilagodi import
import 'package:leami_mobile/screens/article_list.dart'; // <-- prilagodi import

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final PageController _pageController = PageController();

  late ArticleProvider _articleProvider;
  SearchResult<Article>? _result;
  late List<Article> _all;
  late List<Article> _specials;

  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasItems = true;

  late List<ImageProvider> _images;

  @override
  void initState() {
    super.initState();
    _articleProvider = context.read<ArticleProvider>();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _articleProvider.get();
    setState(() {
      _result = data;
      _all = _result?.items ?? _result?.items ?? <Article>[];

      // --- FILTER SPECJALI ---
      // Pokušaj više naziva booleana (prilagodi prema svom modelu)
      _specials = _all.where((a) => _isSpecial(a)).toList();

      _hasItems = _specials.isNotEmpty;
      _isLoading = false;

      // --- PRE-CACHE SLIKE ---
      _images = _specials.map((a) {
        final bytes = _decodeBase64Image(a);
        if (bytes != null) {
          final img = Image.memory(bytes);
          precacheImage(img.image, context);
          return img.image;
        } else {
          const fallback = AssetImage('assets/images/RestoranteLogo.png');
          precacheImage(fallback, context);
          return fallback;
        }
      }).toList();
    });
  }

  // Helper: provjeri više mogućih polja za “specijalitet”
  bool _isSpecial(Article a) {
    try {
      // Ako ima striktno polje:
      // return a.speciality == true || a.isSpecial == true || a.featured == true;
      final map = a.toJson() as Map<String, dynamic>;
      final candidates = ['speciality', 'isSpecial', 'featured', 'isFeatured'];
      for (final key in candidates) {
        final v = map[key];
        if (v is bool && v) return true;
        if (v is int && v == 1) return true;
      }
    } catch (_) {}
    return false;
  }

  // Helper: izvuci base64 sliku iz više mogućih polja
  Uint8List? _decodeBase64Image(Article a) {
    try {
      final map = a.toJson() as Map<String, dynamic>;
      // pokušaj par standardnih ključeva
      final candidates = ['articleImage', 'image', 'photo', 'picture'];
      String? b64;

      for (final key in candidates) {
        final v = map[key];
        if (v is String && v.isNotEmpty) {
          b64 = v;
          break;
        }
      }
      if (b64 == null || b64.isEmpty) return null;
      final pure = b64.contains(',') ? b64.split(',').last : b64;
      return base64Decode(pure);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasItems) {
      return Scaffold(body: Stack(children: [_dishesNotFoundBuilder()]));
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _specials.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (_, index) => _specialCard(index),
          ),
          _leftArrow(),
          _rightArrow(),
          _indicatorDots(),
        ],
      ),
    );
  }

  // --- UI komadi ---

  Stack _specialCard(int index) {
    final a = _specials[index];
    final title = _readString(a, ['name', 'title', 'articleName']) ?? 'Artikal';
    final desc =
        _readString(a, ['description', 'articleDescription', 'details']) ?? '';

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Image(
            image: _images[index],
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'SPECIJALITETI',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ArticleList()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('IDI NA JELOVNIK'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // čita string iz više mogućih ključeva
  String? _readString(Article a, List<String> keys) {
    try {
      final map = a.toJson() as Map<String, dynamic>;
      for (final k in keys) {
        final v = map[k];
        if (v is String && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  Positioned _indicatorDots() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_specials.length, (index) {
          final active = _currentIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            height: 12.0,
            width: active ? 12.0 : 8.0,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  Positioned _rightArrow() {
    return Positioned(
      right: 10,
      top: 200,
      child: IconButton(
        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onPressed: _nextPage,
      ),
    );
  }

  Positioned _leftArrow() {
    return Positioned(
      left: 10,
      top: 200,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: _previousPage,
      ),
    );
  }

  void _nextPage() {
    if (_currentIndex < _specials.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  Stack _dishesNotFoundBuilder() {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            'assets/images/RestoranteLogo.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'UPSSS',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Trenutno nema specijaliteta :(",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  "Posjeti jelovnik i pronađi nešto ukusno! 😋",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ArticleList()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('IDI NA JELOVNIK'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
