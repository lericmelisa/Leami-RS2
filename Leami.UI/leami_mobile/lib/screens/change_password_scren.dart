import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:leami_mobile/providers/user_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  final int userId;
  const ChangePasswordScreen({super.key, required this.userId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _oldVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;

  late UserProvider _userProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promjena lozinke')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'oldPassword',
                obscureText: !_oldVisible,
                decoration: InputDecoration(
                  labelText: 'Stara lozinka',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _oldVisible = !_oldVisible),
                    icon: Icon(
                      _oldVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    tooltip: _oldVisible ? 'Sakrij' : 'Prikaži',
                  ),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: 'Unesite staru lozinku.',
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              FormBuilderTextField(
                name: 'newPassword',
                obscureText: !_newVisible,
                decoration: InputDecoration(
                  labelText: 'Nova lozinka',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _newVisible = !_newVisible),
                    icon: Icon(
                      _newVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    tooltip: _newVisible ? 'Sakrij' : 'Prikaži',
                  ),
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return 'Unesite novu lozinku.';
                  if (v.length < 8) return 'Najmanje 8 znakova.';
                  if (!RegExp(r'[a-z]').hasMatch(v))
                    return 'Mora imati malo slovo.';
                  if (!RegExp(r'[A-Z]').hasMatch(v))
                    return 'Mora imati veliko slovo.';
                  if (!RegExp(r'\d').hasMatch(v)) return 'Mora imati broj.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              FormBuilderTextField(
                name: 'confirmPassword',
                obscureText: !_confirmVisible,
                decoration: InputDecoration(
                  labelText: 'Potvrdi novu lozinku',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _confirmVisible = !_confirmVisible),
                    icon: Icon(
                      _confirmVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    tooltip: _confirmVisible ? 'Sakrij' : 'Prikaži',
                  ),
                ),
                validator: (value) {
                  final newPass =
                      _formKey.currentState?.fields['newPassword']?.value ?? '';
                  if ((value ?? '').trim().isEmpty) return 'Potvrdite lozinku.';
                  if (value != newPass) return 'Lozinke se ne podudaraju.';
                  return null;
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _onSubmit,
                  child: Text(_loading ? 'Mijenjam…' : 'Promijeni lozinku'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    final ok = _formKey.currentState?.saveAndValidate() ?? false;

    // Ako forma nije validna, pokušaj izvući smislen razlog i prikaži popup
    if (!ok) {
      final errors = _formKey.currentState?.fields.map(
        (k, v) => MapEntry(k, v.errorText),
      );
      final msg =
          errors?.values.firstWhere(
            (e) => e != null && e.trim().isNotEmpty,
            orElse: () => 'Provjerite unesena polja.',
          ) ??
          'Provjerite unesena polja.';
      _showErrorDialog(msg);
      return;
    }

    final oldPass = (_formKey.currentState!.value['oldPassword'] as String)
        .trim();
    final newPass = (_formKey.currentState!.value['newPassword'] as String)
        .trim();
    final confirmPass =
        (_formKey.currentState!.value['confirmPassword'] as String).trim();

    if (newPass != confirmPass) {
      _showErrorDialog('Lozinke se ne podudaraju.');
      return;
    }

    setState(() => _loading = true);
    try {
      // Ako backend vraća detaljnu poruku (npr. "Incorrect password."),
      // UserProvider.passChange će baciti Exception s tim tekstom – hvata se ispod.
      await _userProvider.passChange(widget.userId, oldPass, newPass);

      if (!mounted) return;
      Navigator.of(context).pop(true); // signal uspjeha roditeljskom ekranu
    } catch (e) {
      if (!mounted) return;

      // Normalizuj poruku sa servera
      final raw = e.toString();

      // Pokušaj pogoditi poznate Identity poruke (ili vlastite server-side poruke)
      String message;
      if (raw.contains('Incorrect password') ||
          raw.contains('pogrešna') ||
          raw.toLowerCase().contains('old') &&
              raw.toLowerCase().contains('password')) {
        message = 'Neispravna stara lozinka.';
      } else if (raw.toLowerCase().contains('must be at least') ||
          raw.toLowerCase().contains('required length') ||
          raw.toLowerCase().contains('passwords must')) {
        message = 'Nova lozinka ne zadovoljava pravila složenosti.';
      } else if (raw.contains('Unauthorized') || raw.contains('(401)')) {
        message = 'Niste autorizovani za ovu akciju.';
      } else {
        // fallback – prikaži originalni tekst (ili ga ulepšaj)
        message = raw.replaceAll('Exception: ', '').trim();
        if (message.isEmpty)
          message = 'Došlo je do greške pri promjeni lozinke.';
      }

      _showErrorDialog(message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true, // može i tap izvan da zatvori
      builder: (ctx) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Greška'),
              // X u gornjem desnom uglu
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Zatvori',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
