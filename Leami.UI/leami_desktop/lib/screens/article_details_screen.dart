import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:leami_desktop/models/article_category.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/providers/article_category_provider.dart';
import 'package:provider/provider.dart';
import 'package:leami_desktop/models/article.dart';
import 'package:leami_desktop/providers/article_provider.dart';

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
            decoration: const InputDecoration(labelText: 'Naziv artikla'),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: 'Naziv artikla ne može biti prazno.',
              ),
              FormBuilderValidators.minLength(
                2,
                errorText: "Naziv artikla ne može biti manje od 2 znaka.",
              ),
              FormBuilderValidators.maxLength(
                50,
                errorText: "Naziv artikla ne može biti više od 50 znakova.",
              ),
            ]),
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'articlePrice',
            decoration: const InputDecoration(labelText: 'Cijena artikla'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: 'Cijena artikla ne može biti prazna.',
              ),
              (v) {
                if (v == null || v.isEmpty) return null;
                // ne dozvoljava zarez
                if (v.contains(',')) {
                  return 'Koristi tačku umjesto zareza (npr. 14.50).';
                }
                // provjera formata: broj, jedna tačka i do 2 decimale
                final regex = RegExp(r'^\d+(\.\d{1,2})?$');
                if (!regex.hasMatch(v)) {
                  return 'Unesi važeću cijenu s tačkom (npr. 14.50).';
                }
                final d = double.tryParse(v);
                if (d == null) return 'Nevažeći broj.';
                if (d < 0 || d > 1000) {
                  return 'Cijena artikla može biti u rasponu od 0 do 1000.';
                }
                return null;
              },
            ]),
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'articleDescription',
            decoration: const InputDecoration(labelText: 'Opis artikla'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          FormBuilderDropdown<int>(
            name: 'categoryId',
            decoration: const InputDecoration(labelText: 'Kategorija'),
            items: categories!.items!
                .map(
                  (c) => DropdownMenuItem(
                    value: c.categoryId,
                    child: Text(c.categoryName ?? 'N/A'),
                  ),
                )
                .toList(),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: 'Kategorija je obavezna.',
              ),
            ]),
          ),

          const SizedBox(height: 12),
          FormBuilderField<String>(
            name: 'articleImage',
            validator: (val) {
              // Ako nema postojeće slike i ništa nije birano — greška
              if ((val == null || val.isEmpty) && _base64Image == null) {
                return 'Slika artikla je obavezna.';
              }
            },
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Artikal kreiran.'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            await articleProvider.update(widget.article!.articleId!, raw);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Artikal ažuriran.'),
                backgroundColor: Colors.green,
              ),
            );
          }
          // vratimo true da lista zna da treba refresh
          Navigator.of(context).pop(true);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      },
      child: const Text('Spremi'),
    );
  }
}
