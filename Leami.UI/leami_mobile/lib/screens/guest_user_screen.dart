import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/models/user.dart';
import 'package:leami_mobile/models/user_role.dart';
import 'package:leami_mobile/providers/auth_provider.dart';
import 'package:leami_mobile/providers/user_provider.dart';
import 'package:leami_mobile/providers/user_role_provider.dart';
import 'package:provider/provider.dart';

class GuestUserScreen extends StatefulWidget {
  User? user;
  GuestUserScreen({super.key, this.user});

  @override
  State<GuestUserScreen> createState() => GuestUserScreenState();
}

class GuestUserScreenState extends State<GuestUserScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic> _initialValue = {};
  ImageProvider? _imagePreview;
  String? _base64Image;
  bool providerInitialized = false;

  late UserProvider userProvider;
  late UserRoleProvider userRoleProvider;

  SearchResult<UserRole>? roles;
  int? _selectedRoleId;
  String? _selectedRoleName;

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
        'jobTitle': widget.user!.jobTitle,
        'hireDate': widget.user!.hireDate,
        'note': widget.user!.note,
        'userImage': widget.user!.userImage,
      };

      _selectedRoleId = widget.user!.role?.id;
      _selectedRoleName = widget.user!.role?.name;

      final img = widget.user!.userImage;
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
      _initialValue = {
        'firstName': '',
        'lastName': '',
        'email': '',
        'phoneNumber': '',
        'roles': null,
        'jobTitle': '',
        'hireDate': null,
        'note': '',
        'userImage': null,
        'password': '',
      };
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userProvider = context.read<UserProvider>();
    userRoleProvider = context.read<UserRoleProvider>();
    providerInitialized = true;
    initFormData();
  }

  initFormData() async {
    roles = await userRoleProvider.get();
    if (widget.user != null && widget.user!.role != null) {
      formKey.currentState?.fields['roles']?.didChange(widget.user!.role!.id);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
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

        if (raw['hireDate'] != null && raw['hireDate'] is DateTime) {
          raw['hireDate'] = (raw['hireDate'] as DateTime).toIso8601String();
        }

        if (_selectedRoleId != null) {
          raw['roleIds'] = [_selectedRoleId];
        }
        raw.remove('role');
        raw.remove('roles');

        if (_base64Image != null && _base64Image!.isNotEmpty) {
          raw['userImage'] = _base64Image;
        } else {
          raw['userImage'] = null;
        }

        try {
          if (widget.user == null) {
            widget.user = await userProvider.insert(raw);

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('User created.')));
          } else {
            widget.user = await userProvider.update(widget.user!.id!, raw);
            // debugPrint("📤 UPDATE request: ${jsonEncode(raw)}");
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('User updated.')));
          }

          AuthProvider.user = widget.user;

          // patchamo formu na nove vrijednosti:
          formKey.currentState?.patchValue({
            'firstName': widget.user!.firstName,
            'lastName': widget.user!.lastName,
            'email': widget.user!.email,
            'phoneNumber': widget.user!.phoneNumber,
          });

          // ako je došla nova slika, dekodiramo i postavljamo preview
          if (widget.user!.userImage != null &&
              widget.user!.userImage!.isNotEmpty) {
            final pureBase64 = widget.user!.userImage!.contains(',')
                ? widget.user!.userImage!.split(',').last
                : widget.user!.userImage!;
            final bytes = base64Decode(pureBase64);
            setState(() {
              _base64Image = pureBase64;
              _imagePreview = MemoryImage(bytes);
            });
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
        setState(() {});
      },
      child: const Text('Spremi'),
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
            name: 'firstName',
            decoration: const InputDecoration(labelText: 'Ime'),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Ime je obavezno.'),
              FormBuilderValidators.minLength(
                2,
                errorText: 'Minimalno 2 znaka.',
              ),
            ]),
          ),
          const SizedBox(height: 12),

          FormBuilderTextField(
            name: 'lastName',
            decoration: const InputDecoration(labelText: 'Prezime'),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Prezime je obavezno.'),
              FormBuilderValidators.minLength(
                2,
                errorText: 'Minimalno 2 znaka.',
              ),
            ]),
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'email',
            decoration: const InputDecoration(labelText: 'E-mail'),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'E-mail je obavezan.'),
              FormBuilderValidators.minLength(
                2,
                errorText: 'Minimalno 2 znaka.',
              ),
            ]),
          ),
          const SizedBox(height: 12),

          FormBuilderTextField(
            name: 'password',
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Unesite novu lozinku',
            ),
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'phoneNumber',
            decoration: const InputDecoration(labelText: 'Broj telefona'),
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 16),

          FormBuilderField<String>(
            name: 'userImage',
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
