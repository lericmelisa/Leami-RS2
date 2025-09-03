import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:leami_mobile/models/article_category.dart';
import 'package:leami_mobile/providers/article_category_provider.dart';
import 'package:provider/provider.dart';

class ArticleCategoryDetailsScreen extends StatefulWidget {
  final ArticleCategory? category;
  const ArticleCategoryDetailsScreen({super.key, this.category});

  @override
  State<ArticleCategoryDetailsScreen> createState() =>
      _ArticleCategoryDetailsScreenState();
}

class _ArticleCategoryDetailsScreenState
    extends State<ArticleCategoryDetailsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  late ArticleCategoryProvider _provider;
  late Map<String, dynamic> _initialData;

  @override
  void initState() {
    super.initState();
    _initialData = {'categoryName': widget.category?.categoryName ?? ''};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<ArticleCategoryProvider>();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.category == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Nova kategorija' : 'Uredi kategoriju'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          initialValue: _initialData,
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'categoryName',
                decoration: const InputDecoration(labelText: 'Naziv'),
                validator: FormBuilderValidators.required(
                  errorText: 'Naziv je obavezan',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                child: Text(isNew ? 'Kreiraj' : 'Spremi'),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final data = _formKey.currentState!.value;
    try {
      if (widget.category == null) {
        await _provider.insert({'categoryName': data['categoryName']});
      } else {
        await _provider.update(widget.category!.categoryId!, {
          'categoryName': data['categoryName'],
        });
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška: $e')));
    }
  }
}
