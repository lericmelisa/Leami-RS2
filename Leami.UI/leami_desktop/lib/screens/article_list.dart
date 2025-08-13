import 'package:flutter/material.dart';
import 'package:leami_desktop/providers/article_provider.dart';
import 'package:leami_desktop/layouts/master_screen.dart';
import 'package:provider/provider.dart';

class ArticleList extends StatefulWidget {
  const ArticleList({super.key});

  @override
  State<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<ArticleList> {
  late ArticleProvider articleProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    articleProvider = context.read<ArticleProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Lista Artikala",
      child: Center(child: Column(children: [_buildSearch()])),
    );
  }

  Widget _buildSearch() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Pretražite artikle po nazivu',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.yellow, // jarka boja da odmah vidiš polje
      ),
      onChanged: (value) {
        var articles = articleProvider.fetchArticles();
        debugPrint(articles.toString());
        print("TUUUUUUUUUUUUUUUUUUUU SAMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM");
        // Implement search logic here, possibly filtering the articles list based on the input value.
      },
    );
  }
}
