import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:leami_desktop/models/article_category.dart';
import 'package:leami_desktop/providers/article_category_provider.dart';
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
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: 'Naziv kategorije je obavezan.',
                  ),
                  FormBuilderValidators.minLength(
                    2,
                    errorText:
                        'Naziv kategorije ne može imati manje od 2 znaka.',
                  ),
                  FormBuilderValidators.maxLength(
                    50,
                    errorText:
                        'Naziv kategorije ne može imati više od 50 znakova.',
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(isNew ? 'Kreiraj' : 'Spremi'),
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

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategorija dodana.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _provider.update(widget.category!.categoryId!, {
          'categoryName': data['categoryName'],
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategorija uređena.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
