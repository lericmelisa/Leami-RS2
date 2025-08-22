import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:leami_desktop/models/article_category.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/providers/article_category_provider.dart';
import 'package:provider/provider.dart';
import 'package:leami_desktop/models/article.dart';
import 'package:leami_desktop/providers/article_provider.dart';

class ArticleDetailsScreen extends StatefulWidget {
  Article? article;
  ArticleDetailsScreen({super.key, this.article});

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();

  Map<String, dynamic> _initialValue = {};
  ImageProvider? _imagePreview;
  String? _base64Image;
  bool providerInitialized = false;

  late ArticleProvider articleProvider;
  late ArticleCategoryProvider articlecategoryProvider;

  SearchResult<ArticleCategory>? categories;

  @override
  void initState() {
    super.initState();
    articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    articlecategoryProvider = Provider.of<ArticleCategoryProvider>(
      context,
      listen: false,
    );

    if (widget.article != null) {
      _initialValue = {
        'articleName': widget.article!.articleName,
        'articlePrice': widget.article!.articlePrice?.toString(),
        'articleDescription': widget.article!.articleDescription,
        'categoryId': widget.article!.categoryId,
        'articleImage': widget.article!.articleImage,
      };

      final img = widget.article!.articleImage;
      if (img.isNotEmpty) {
        try {
          final pureBase64 = img.contains(',') ? img.split(',').last : img;
          final decoded = base64Decode(pureBase64);
          _imagePreview = MemoryImage(decoded);
          _base64Image = pureBase64;
        } catch (e) {
          debugPrint('Greška pri dekodiranju slike: $e');
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    articleProvider = context.read<ArticleProvider>();
    articlecategoryProvider = context.read<ArticleCategoryProvider>();
    providerInitialized = true;
    initFormData();
  }

  initFormData() async {
    categories = await articlecategoryProvider.get();

    if (widget.article != null && widget.article!.categoryId != null) {
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (categories == null)
                const Center(child: CircularProgressIndicator())
              else
                _buildForm(),
              const SizedBox(height: 16),
              _buildSaveButton(), // ElevatedButton -> narandžast
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () async {
        final ok = formKey.currentState?.saveAndValidate() ?? false;
        if (!ok) return;

        final raw = Map<String, dynamic>.from(formKey.currentState!.value);

        try {
          if (widget.article == null) {
            widget.article = await articleProvider.insert(raw);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Article created.')));
          } else {
            widget.article = await articleProvider.update(
              widget.article!.articleId!,
              raw,
            );
            print('Article updated: $raw');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Article updated.')));
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
        setState(() {});
      },
      child: const Text('Save'),
    );
  }

  Widget _buildForm() {
    return FormBuilder(
      key: formKey,
      initialValue: _initialValue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormBuilderTextField(
            name: 'articleName',
            decoration: const InputDecoration(labelText: 'Article Name'),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Naziv je obavezan.'),
              FormBuilderValidators.minLength(
                2,
                errorText: 'Minimalno 2 znaka.',
              ),
            ]),
          ),
          const SizedBox(height: 12),

          FormBuilderTextField(
            name: 'articlePrice',
            decoration: const InputDecoration(labelText: 'Article Price'),
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Cijena je obavezna.'),
              (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null) return 'Unesite validan broj.';
                if (parsed < 0) return 'Cijena mora biti >= 0.';
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

          Row(
            children: [
              Expanded(
                child: FormBuilderDropdown(
                  name: "categoryId",
                  decoration: const InputDecoration(
                    labelText: "Article Category",
                  ),
                  items:
                      categories?.items
                          ?.map(
                            (e) => DropdownMenuItem(
                              value: e.categoryId,
                              child: Text(e.categoryName ?? 'N/A'),
                            ),
                          )
                          .toList() ??
                      [],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          FormBuilderField<String>(
            name: 'articleImage',
            validator: (value) {
              if ((value == null || value.isEmpty) &&
                  (_base64Image == null || _base64Image!.isEmpty)) {
                return 'Morate dodati sliku.';
              }
              return null;
            },
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imagePreview != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image(
                            image: _imagePreview!,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Text('Nema slike'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text('Odaberi sliku'),
                        onPressed: () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              final file = File(result.files.single.path!);
                              final bytes = await file.readAsBytes();
                              final b64 = base64Encode(bytes);

                              setState(() {
                                _base64Image = b64;
                                _imagePreview = MemoryImage(bytes);
                              });

                              field.didChange(b64);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Greška pri izboru slike: $e'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      if (_imagePreview != null)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Ukloni'),
                          onPressed: () {
                            setState(() {
                              _base64Image = null;
                              _imagePreview = null;
                            });
                            field.didChange(null);
                          },
                        ),
                    ],
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        field.errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
