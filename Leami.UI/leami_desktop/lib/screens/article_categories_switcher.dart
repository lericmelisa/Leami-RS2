import 'package:flutter/material.dart';
import 'package:leami_desktop/screens/article_list.dart';
import 'package:leami_desktop/screens/article_category_list.dart';

class ArticlesCategoriesSwitcher extends StatefulWidget {
  const ArticlesCategoriesSwitcher({super.key});

  @override
  State<ArticlesCategoriesSwitcher> createState() =>
      _ArticlesCategoriesSwitcherState();
}

class _ArticlesCategoriesSwitcherState
    extends State<ArticlesCategoriesSwitcher> {
  bool _showArticles = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            // Toggle buttons za artikle / kategorije
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showArticles = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showArticles
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text('Upravljanje artiklima'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showArticles = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showArticles
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text('Upravljanje kategorijama'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pretraga + lista
            Expanded(
              child: _showArticles
                  ? const ArticleList()
                  : const ArticleCategoryList(),
            ),
          ],
        ),
      ),
    );
  }
}
