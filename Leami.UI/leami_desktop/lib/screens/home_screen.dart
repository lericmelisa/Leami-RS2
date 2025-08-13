import 'package:flutter/material.dart';
import 'package:leami_desktop/layouts/master_screen.dart';
import 'package:leami_desktop/screens/article_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'NASLOVNA STRANICA',
      child: Center(child: ArticleList()),
    );
  }
}
