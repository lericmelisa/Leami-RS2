import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:leami_mobile/models/article.dart';
import 'package:leami_mobile/models/article_category.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/providers/article_category_provider.dart';
import 'package:leami_mobile/providers/article_provider.dart';
import 'package:provider/provider.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final Article? article;
  const ArticleDetailsScreen({super.key, this.article});

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic> _initialValue = {};
  ImageProvider? _imagePreview;
  String? _base64Image;

  late ArticleProvider articleProvider;
  late ArticleCategoryProvider categoryProvider;
  SearchResult<ArticleCategory>? categories;

  @override
  void initState() {
    super.initState();
    articleProvider = context.read<ArticleProvider>();
    categoryProvider = context.read<ArticleCategoryProvider>();

    if (widget.article != null) {
      _initialValue = {
        'articleName': widget.article!.articleName,
        'articlePrice': widget.article!.articlePrice?.toString(),
        'articleDescription': widget.article!.articleDescription,
        'categoryId': widget.article!.categoryId,
        'articleImage': widget.article!.articleImage,
      };
      final img = widget.article!.articleImage;
      if (img != null && img.isNotEmpty) {
        try {
          final pure = img.contains(',') ? img.split(',').last : img;
          final bytes = base64Decode(pure);
          _imagePreview = MemoryImage(bytes);
          _base64Image = pure;
        } catch (_) {
          /* ignore */
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    categories = await categoryProvider.get();
    if (widget.article != null) {
      formKey.currentState?.fields['categoryId']?.didChange(
        widget.article!.categoryId,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Article Details')),
      body: categories == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildForm() {
    return FormBuilder(
      key: formKey,
      initialValue: _initialValue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormBuilderTextField(
            name: 'articleName',
            decoration: const InputDecoration(labelText: 'Article Name'),
            validator: FormBuilderValidators.required(
              errorText: 'Naziv je obavezan.',
            ),
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'articlePrice',
            decoration: const InputDecoration(labelText: 'Article Price'),
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Cijena je obavezna.'),
              (v) {
                if (v == null || v.isEmpty) return null;
                final d = double.tryParse(v.replaceAll(',', '.'));
                if (d == null) return 'Nevažeći broj';
                if (d < 0) return 'Mora biti ≥ 0';
                return null;
              },
            ]),
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'articleDescription',
            decoration: const InputDecoration(labelText: 'Article Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          FormBuilderDropdown<int>(
            name: 'categoryId',
            decoration: const InputDecoration(labelText: 'Category'),
            items: categories!.items!
                .map(
                  (c) => DropdownMenuItem(
                    value: c.categoryId,
                    child: Text(c.categoryName ?? 'N/A'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          FormBuilderField<String>(
            name: 'articleImage',
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_imagePreview != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: _imagePreview!,
                        width: 140,
                        height: 140,
                      ),
                    )
                  else
                    const Text('Nema slike'),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text('Odaberi sliku'),
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (res != null && res.files.single.path != null) {
                            final bytes = await File(
                              res.files.single.path!,
                            ).readAsBytes();
                            setState(() {
                              _base64Image = base64Encode(bytes);
                              _imagePreview = MemoryImage(bytes);
                            });
                            field.didChange(_base64Image);
                          }
                        },
                      ),
                    ],
                  ),
                  if (field.hasError)
                    Text(
                      field.errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () async {
        final ok = formKey.currentState?.saveAndValidate() ?? false;
        if (!ok) return;
        final raw = Map<String, dynamic>.from(formKey.currentState!.value);
        if (_base64Image != null) raw['articleImage'] = _base64Image;
        try {
          if (widget.article == null) {
            await articleProvider.insert(raw);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Article created.')));
          } else {
            await articleProvider.update(widget.article!.articleId!, raw);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Article updated.')));
          }
          // vratimo `true` da lista zna da treba refresh
          Navigator.of(context).pop(true);
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
      child: const Text('Save'),
    );
  }
}
