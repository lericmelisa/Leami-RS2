import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/models/user.dart';
import 'package:leami_desktop/models/user_role.dart';
import 'package:leami_desktop/providers/auth_provider.dart';
import 'package:leami_desktop/providers/user_provider.dart';
import 'package:leami_desktop/providers/user_role_provider.dart';
import 'package:provider/provider.dart';

class AdminDetailsScreen extends StatefulWidget {
  User? user;
  AdminDetailsScreen({super.key, this.user});

  @override
  State<AdminDetailsScreen> createState() => _AdminDetailsScreenState();
}

class _AdminDetailsScreenState extends State<AdminDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic> _initialValue = {};
  ImageProvider? _imagePreview;
  String? _base64Image;
  final _emailFocus = FocusNode();

  bool _passwordVisible = false;
  late UserProvider userProvider;
  late UserRoleProvider userRoleProvider;

  SearchResult<UserRole>? roles;
  int? _selectedRoleId;
  bool _removeImage = false;

  @override
  void dispose() {
    _emailFocus.dispose(); // <— obavezno
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    userRoleProvider = Provider.of<UserRoleProvider>(context, listen: false);

    if (widget.user != null) {
      _initialValue = {
        'firstName': widget.user!.firstName,
        'lastName': widget.user!.lastName,
        'email': widget.user!.email,
        'phoneNumber': widget.user!.phoneNumber,
        'roles': widget.user!.role?.id,
        'userImage': widget.user!.userImage,
        'password': '',
      };

      _selectedRoleId = widget.user!.role?.id;

      final img = widget.user!.userImage;
      if (img != null && img.isNotEmpty) {
        try {
          final pureBase64 = img.contains(',') ? img.split(',').last : img;
          final decoded = base64Decode(pureBase64);
          _imagePreview = MemoryImage(decoded);
          _base64Image = pureBase64;
        } catch (_) {}
      }
    } else {
      _initialValue = {
        'firstName': '',
        'lastName': '',
        'email': '',
        'phoneNumber': '',
        'roles': null,
        'userImage': null,
        'password': '',
      };
    }

    _initFormData();
  }

  Future<void> _initFormData() async {
    roles = await userRoleProvider.get();
    if (widget.user != null && widget.user!.role != null) {
      formKey.currentState?.fields['roles']?.didChange(widget.user!.role!.id);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Korisnički profil')),
      body: SingleChildScrollView(
        primary: true,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (roles == null)
              const Center(child: CircularProgressIndicator())
            else
              _buildForm(),
            const SizedBox(height: 16),
            _buildSaveButton(),
          ],
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

        if (_selectedRoleId != null) {
          raw['roleIds'] = [_selectedRoleId];
        }
        raw.remove('role');
        raw.remove('roles');

        final pass = (raw['password'] as String?)?.trim();
        if (pass == null || pass.isEmpty) {
          raw.remove('password');
        }

        if (_removeImage) {
          raw['userImage'] = null;
        } else if (_base64Image != null && _base64Image!.isNotEmpty) {
          raw['userImage'] = _base64Image;
        } else {
          raw.remove('userImage');
        }

        try {
          if (widget.user == null) {
            widget.user = await userProvider.insert(raw);
          } else {
            widget.user = await userProvider.update(widget.user!.id!, raw);
          }

          if (AuthProvider.user != null &&
              widget.user != null &&
              AuthProvider.user!.id == widget.user!.id) {
            AuthProvider.user = widget.user;
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sačuvano.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          } else {
            setState(() {});
          }
        } catch (e) {
          final s = e.toString();

          // samo za 409 (duplikat email/username)
          if (RegExp(r'HTTP\s*409').hasMatch(s) ||
              s.contains('"status":409') ||
              s.toLowerCase().contains('conflict')) {
            const msg = 'Već postoji korisnik s tom email adresom.';

            final emailField = formKey.currentState?.fields['email'];
            emailField?.invalidate(msg); // prikaži grešku ispod polja

            // pop-up
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Ne može se spremiti'),
                content: const Text(msg),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('U redu'),
                  ),
                ],
              ),
            );

            // očisti vrijednost i fokusiraj polje
            emailField?.didChange('');
            if (mounted) {
              FocusScope.of(context).requestFocus(_emailFocus);
            }
            return; // prekini dalje rukovanje
          }

          // ostale greške prikaži generički
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
      child: const Text('Spremi'),
    );
  }

  Widget _buildForm() {
    return FormBuilder(
      key: formKey,
      initialValue: _initialValue,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double gutter = 16;
          final bool isWide = constraints.maxWidth >= 900;
          final double fieldWidth = isWide
              ? (constraints.maxWidth - gutter) / 2
              : constraints.maxWidth;

          final items = <Widget>[
            SizedBox(
              width: fieldWidth,
              child: FormBuilderTextField(
                name: 'firstName',
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: 'Ime je obavezno.'),
                  FormBuilderValidators.minLength(
                    2,
                    errorText: 'Minimalno 2 znaka.',
                  ),
                ]),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: FormBuilderTextField(
                name: 'lastName',
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: 'Prezime je obavezno.',
                  ),
                  FormBuilderValidators.minLength(
                    2,
                    errorText: 'Minimalno 2 znaka.',
                  ),
                ]),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: FormBuilderTextField(
                name: 'email',
                focusNode: _emailFocus,
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (_) {
                  formKey.currentState?.fields['email']?.validate();
                },
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: 'Email je obavezan.',
                  ),
                  FormBuilderValidators.email(
                    errorText:
                        'Unesite ispravan email (npr. korisnik@example.com).',
                  ),
                ]),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: FormBuilderTextField(
                name: 'phoneNumber',
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: FormBuilderTextField(
                name: 'password',
                obscureText: !_passwordVisible,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: 'Nova lozinka (opcionalno)',
                  suffixIcon: IconButton(
                    tooltip: _passwordVisible
                        ? 'Sakrij lozinku'
                        : 'Prikaži lozinku',
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return null;
                  if (v.length < 8)
                    return 'Lozinka mora imati najmanje 8 znakova.';
                  if (!RegExp(r'[a-z]').hasMatch(v)) {
                    return 'Lozinka mora sadržavati barem jedno malo slovo.';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(v)) {
                    return 'Lozinka mora sadržavati barem jedno veliko slovo.';
                  }
                  if (!RegExp(r'\d').hasMatch(v)) {
                    return 'Lozinka mora sadržavati barem jedan broj.';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: FormBuilderDropdown<int>(
                name: "roles",
                enabled: false,
                initialValue: _selectedRoleId,
                decoration: const InputDecoration(labelText: "Administrator"),
                items:
                    roles?.items
                        ?.map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name ?? 'N/A'),
                          ),
                        )
                        .toList() ??
                    [],
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: FormBuilderField<String>(
                name: 'userImage',
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.upload),
                            label: const Text('Odaberi sliku'),
                            onPressed: () async {
                              final res = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                              );
                              if (res != null &&
                                  res.files.single.path != null) {
                                final bytes = await File(
                                  res.files.single.path!,
                                ).readAsBytes();
                                setState(() {
                                  _removeImage = false;
                                  _base64Image = base64Encode(bytes);
                                  _imagePreview = MemoryImage(bytes);
                                });
                                field.didChange(_base64Image);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          if (_imagePreview != null)
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Ukloni sliku'),
                              onPressed: () {
                                setState(() {
                                  _removeImage = true;
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
                            field.errorText ?? '',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ];

          return Wrap(spacing: gutter, runSpacing: 12, children: items);
        },
      ),
    );
  }
}
