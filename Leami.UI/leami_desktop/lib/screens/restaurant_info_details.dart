import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:leami_desktop/models/restaurant_info.dart';
import 'package:leami_desktop/providers/restaurant_info_provider.dart';
import 'package:provider/provider.dart';

class RestaurantInfoDetailsScreen extends StatefulWidget {
  final RestaurantInfo? info;
  const RestaurantInfoDetailsScreen({super.key, this.info});

  @override
  State<RestaurantInfoDetailsScreen> createState() =>
      _RestaurantInfoDetailsScreenState();
}

class _RestaurantInfoDetailsScreenState
    extends State<RestaurantInfoDetailsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  late RestaurantInfoProvider _provider;
  late Map<String, dynamic> initialValue;

  ImageProvider? _imagePreview;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    if (widget.info != null) {
      initialValue = {
        'name': widget.info?.name ?? '',
        'description': widget.info?.description,
        'address': widget.info?.address,
        'phone': widget.info?.phone,
        'openingSpan': _parseSpan(widget.info?.openingTime ?? '09:00:00'),
        'closingSpan': _parseSpan(widget.info?.closingTime ?? '17:00:00'),
        'restaurantImage': widget.info?.restaurantImage ?? '',
      };

      final img = widget.info!.restaurantImage;
      if (img != null && img.isNotEmpty) {
        try {
          final pureBase64 = img.contains(',') ? img.split(',').last : img;
          final decoded = base64Decode(pureBase64);
          _imagePreview = MemoryImage(decoded);
          _base64Image = pureBase64;
        } catch (e) {
          debugPrint('Greška pri dekodiranju slike: $e');
        }
      }
    } else {
      initialValue = {
        'name': '',
        'description': '',
        'address': '',
        'phone': '',
        'openingSpan': const Duration(hours: 9),
        'closingSpan': const Duration(hours: 17),
        'restaurantImage': null,
      };
    }
    // Provider nakon frame-a
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<RestaurantInfoProvider>();
    });
  }

  // Parsiraj string "HH:mm:ss" u Duration
  Duration _parseSpan(String s) {
    final parts = s.split(':').map(int.parse).toList();
    return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
  }

  // Formatiraj Duration u "HH:mm:ss"
  String _formatSpan(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  // Biranje nove slike
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      setState(() {
        _imagePreview = MemoryImage(bytes);
        _base64Image = base64Encode(bytes);
      });
      // **Ažuriramo** FormBuilderField:
      _formKey.currentState?.fields['restaurantImage']?.didChange(_base64Image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uredi postavke restorana')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1) Full-width tappable image
              FormBuilderField<String>(
                name: 'restaurantImage',
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Samo prikaz slike ili placeholder, bez onTap
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _imagePreview != null
                            ? Image(
                                image: _imagePreview!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              )
                            : Container(
                                height: 200,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(Icons.camera_alt, size: 48),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Dugme za biranje nove slike
                          TextButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Učitaj sliku'),
                            onPressed: _pickImage,
                          ),
                          const SizedBox(width: 16),
                          // Ako već ima preview, prikaži i dugme za brisanje
                          if (_imagePreview != null)
                            TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                'Obriši sliku',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                setState(() {
                                  _imagePreview = null;
                                  _base64Image = null;
                                });
                                // očistimo i form field
                                field.didChange(null);
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

              const SizedBox(height: 16),
              // 2) Naziv restorana
              FormBuilderTextField(
                name: 'name',
                decoration: const InputDecoration(labelText: 'Naziv restorana'),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: 'Naziv restorana ne može biti prazan.',
                  ),
                  FormBuilderValidators.minLength(
                    2,
                    errorText:
                        'Naziv restorana ne može imati manje od 2 znaka.',
                  ),
                  FormBuilderValidators.maxLength(
                    50,
                    errorText:
                        'Naziv restorana ne može imati više od 50 znakova.',
                  ),
                ]),
              ),

              const SizedBox(height: 16),
              // 3) Kratki opis
              FormBuilderTextField(
                name: 'description',
                decoration: const InputDecoration(
                  labelText: 'Kratki opis (description)',
                ),
                maxLines: 3,
                validator: FormBuilderValidators.compose([
                  // ako prazno => nema greške
                  (value) {
                    if (value == null || value.isEmpty) return null;
                    if (value.length > 100) {
                      return 'Opis može imati najviše 100 znakova.';
                    }
                    return null;
                  },
                ]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'address',
                      decoration: const InputDecoration(labelText: 'Adresa'),
                      validator: FormBuilderValidators.maxLength(
                        100,
                        errorText:
                            'Adresa je obavezna i može imati najviše 100 znakova.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'phone',
                      decoration: const InputDecoration(labelText: 'Telefon'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.maxLength(
                          50,
                          errorText:
                              'Telefon je obavezan i može imati najviše 50 znakova.',
                        ),
                        FormBuilderValidators.match(
                          RegExp(r'^\+?[0-9 ]+$'),
                          errorText:
                              'Neispravan format telefona (koristi cifre i opcionalno +).',
                        ),
                      ]),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              // 5) Radno vrijeme: Opening / Closing
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Picker za otvaranje
                    FormBuilderField<Duration>(
                      name: 'openingSpan',
                      validator: FormBuilderValidators.required(
                        errorText: 'Vrijeme otvaranja je obavezno.',
                      ),
                      builder: (field) {
                        final dur = field.value ?? const Duration(hours: 9);
                        return InkWell(
                          onTap: () async {
                            final tod = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: dur.inHours,
                                minute: dur.inMinutes % 60,
                              ),
                            );
                            if (tod != null) {
                              field.didChange(
                                Duration(hours: tod.hour, minutes: tod.minute),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Otvaranje: ${_formatSpan(dur)}'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    // Picker za zatvaranje
                    FormBuilderField<Duration>(
                      name: 'closingSpan',
                      validator: FormBuilderValidators.required(
                        errorText: 'Vrijeme zatvaranja je obavezno.',
                      ),
                      builder: (field) {
                        final dur = field.value ?? const Duration(hours: 17);
                        return InkWell(
                          onTap: () async {
                            final tod = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: dur.inHours,
                                minute: dur.inMinutes % 60,
                              ),
                            );
                            if (tod != null) {
                              field.didChange(
                                Duration(hours: tod.hour, minutes: tod.minute),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Zatvaranje: ${_formatSpan(dur)}'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              // 6) Spremi promjene
              ElevatedButton(
                onPressed: _save,
                child: const Text('Spremi promjene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final raw = Map<String, dynamic>.from(_formKey.currentState!.value);

    final openDur = raw['openingSpan'] as Duration;
    final closeDur = raw['closingSpan'] as Duration;
    if (closeDur <= openDur) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vrijeme zatvaranja mora biti poslije vremena otvaranja.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    raw.remove('openingSpan');
    raw.remove('closingSpan');
    raw['openingTime'] = _formatSpan(openDur);
    raw['closingTime'] = _formatSpan(closeDur);
    // Slika
    if (_base64Image != null) {
      raw['restaurantImage'] = _base64Image;
    } else {
      raw.remove('restaurantImage');
    }

    try {
      if (widget.info == null) {
        await _provider.insert(raw);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kreirane postavke restorana.')),
        );
      } else {
        await _provider.update(widget.info!.restaurantId!, raw);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ažurirane postavke restorana.')),
        );
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
