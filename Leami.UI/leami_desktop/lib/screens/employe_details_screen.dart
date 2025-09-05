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
import 'package:leami_desktop/screens/employee_change_password_screen.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class EmployeDetailsScreen extends StatefulWidget {
  User? user;
  EmployeDetailsScreen({super.key, this.user});

  @override
  State<EmployeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic> _initialValue = {};
  ImageProvider? _imagePreview;
  String? _base64Image;

  bool _passwordVisible = false;
  late UserProvider userProvider;
  late UserRoleProvider userRoleProvider;

  SearchResult<UserRole>? roles;
  int? _selectedRoleId;
  bool _removeImage = false;

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

        raw.remove('role');
        raw.remove('roles');
        raw.remove('roleIds');

        raw.remove('password');

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
          if (!mounted) return;
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
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: FormBuilderTextField(
                name: 'phoneNumber',
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  // Dozvoli samo cifre, +, -, razmak i /
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s/]')),
                ],
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: 'Telefon je obavezan.',
                  ),
                  // Dodatna provjera formata i dužine
                  (val) {
                    final v = (val ?? '').trim();
                    // + opcionalno, cifre/razmaci/-/; 6–20 znakova ukupno
                    final re = RegExp(r'^\+?[0-9\s\-/]{6,20}$');
                    if (!re.hasMatch(v))
                      return 'Unesite ispravan broj telefona.';
                    return null;
                  },
                ]),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_reset),
                label: const Text('Promijeni lozinku'),
                onPressed: () async {
                  if (widget.user?.id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Nije moguće promijeniti lozinku bez korisničkog ID-a.',
                        ),
                      ),
                    );
                    return;
                  }

                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => EmployeeChangePasswordScreen(
                        userId: widget.user!.id!,
                      ),
                    ),
                  );

                  if (changed == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lozinka uspješno promijenjena.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: FormBuilderDropdown<int>(
                name: "roles",
                enabled: false,
                initialValue: _selectedRoleId,
                decoration: const InputDecoration(labelText: "Uloga"),
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
