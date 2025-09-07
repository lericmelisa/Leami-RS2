import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/models/user.dart';
import 'package:leami_desktop/models/user_role.dart';
import 'package:leami_desktop/providers/user_provider.dart';
import 'package:leami_desktop/providers/user_role_provider.dart';
import 'package:provider/provider.dart';

class UserDetailsScreen extends StatefulWidget {
  User? user;
  UserDetailsScreen({super.key, this.user});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic> _initialValue = {};
  ImageProvider? _imagePreview;
  String? _base64Image;
  bool providerInitialized = false;

  bool _passwordVisible = false; // 🔒 toggle za prikaz lozinke

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
        'password': '', //(opcionalna promjena)
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
        final pass = (raw['password'] as String?)?.trim();
        if (pass == null || pass.isEmpty) {
          raw.remove('password');
        }

        try {
          if (widget.user == null) {
            widget.user = await userProvider.insert(raw);
            // Prikaži poruku o uspjehu
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Korisnik je uspješno kreiran!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Vrati se nakon što se frame završi
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            });
          } else {
            widget.user = await userProvider.updateAdmin(widget.user!.id!, raw);

            // Prikaži poruku o uspjehu
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Korisnik je uspješno ažuriran!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Vrati se nakon što se frame završi
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            });
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 2 kolone ako ima dovoljno širine, inače 1
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
                enabled: widget.user == null,
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
                enabled: widget.user == null,
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
                enabled: widget.user == null,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: FormBuilderTextField(
                name: 'phoneNumber',
                enabled: widget.user == null,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
            ),
            // ----- Nova lozinka (opcionalno) -----
            SizedBox(
              width: fieldWidth,
              child: FormBuilderTextField(
                name: 'password',
                obscureText: !_passwordVisible, // <- toggle
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
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) {
                    return null; // prazno = ne mijenja lozinku
                  }
                  if (v.length < 8) {
                    return 'Lozinka mora imati najmanje 8 znakova.';
                  }
                  final hasLower = RegExp(r'[a-z]').hasMatch(v);
                  if (!hasLower) {
                    return 'Lozinka mora sadržavati barem jedno malo slovo.';
                  }
                  final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
                  if (!hasUpper) {
                    return 'Lozinka mora sadržavati barem jedno veliko slovo.';
                  }
                  final hasDigit = RegExp(r'\d').hasMatch(v);
                  if (!hasDigit) {
                    return 'Lozinka mora sadržavati barem jedan broj.';
                  }

                  // Specijalni znak nije potreban jer je RequireNonAlphanumeric = false

                  return null;
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: FormBuilderDropdown<int>(
                name: "roles",
                decoration: const InputDecoration(labelText: "User Role"),
                initialValue: _selectedRoleId,
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
                onChanged: (val) {
                  final role = roles?.items?.firstWhere(
                    (r) => r.id == val,
                    orElse: () => UserRole(),
                  );
                  setState(() {
                    _selectedRoleId = val;
                    _selectedRoleName = role?.name;
                  });
                },
              ),
            ),
            // Employee polja (samo kad je Employee)
            if (_selectedRoleName == "Employee") ...[
              SizedBox(
                width: fieldWidth,
                child: FormBuilderTextField(
                  name: 'jobTitle',
                  decoration: const InputDecoration(labelText: 'Job Title'),
                  validator: FormBuilderValidators.required(
                    errorText: 'Job Title je obavezan.',
                  ),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: FormBuilderDateTimePicker(
                  name: 'hireDate',
                  decoration: const InputDecoration(labelText: 'Hire Date'),
                  inputType: InputType.date,
                  validator: FormBuilderValidators.required(
                    errorText: 'Datum zaposlenja je obavezan.',
                  ),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: FormBuilderTextField(
                  name: 'note',
                  decoration: const InputDecoration(labelText: 'Napomena'),
                  maxLines: 2,
                ),
              ),
            ],
            // Slika
            SizedBox(
              width: fieldWidth,
              child: FormBuilderField<String>(
                name: 'userImage',
                enabled: widget.user == null,
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
            ),
          ];

          return Wrap(
            spacing: gutter, // razmak između kolona
            runSpacing: 12, // vertikalni razmak između redova
            children: items,
          );
        },
      ),
    );
  }
}
