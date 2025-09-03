import 'package:flutter/material.dart';
import 'package:leami_mobile/screens/article_category_list.dart';
import 'package:leami_mobile/screens/article_list.dart';
import 'package:provider/provider.dart';

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showArticles
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: () => setState(() => _showArticles = true),
                    child: const Text('Upravljanje artiklima'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showArticles
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: () => setState(() => _showArticles = false),
                    child: const Text('Upravljanje kategorijama'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _showArticles ? const ArticleList() : const ArticleCategoryList(),
    );
  }
}
