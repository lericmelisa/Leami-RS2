import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:leami_mobile/providers/stripe_service.dart';
import 'package:leami_mobile/providers/article_category_provider.dart';
import 'package:leami_mobile/providers/article_provider.dart';
import 'package:leami_mobile/providers/user_provider.dart';
import 'package:leami_mobile/providers/user_role_provider.dart';
import 'package:leami_mobile/providers/reservation_provider.dart';
import 'package:leami_mobile/providers/review_provider.dart';
import 'package:leami_mobile/providers/restaurant_info_provider.dart';
import 'package:leami_mobile/providers/cart_provider.dart';
import 'package:leami_mobile/providers/order_provider.dart';
import 'package:leami_mobile/providers/order_response_provider.dart';
import 'package:leami_mobile/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:leami_mobile/screens/login_page.dart';
import 'package:leami_mobile/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await StripeService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ArticleProvider()),
        ChangeNotifierProvider(create: (_) => ArticleCategoryProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => UserRoleProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantInfoProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => OrderResponseProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark(),
      theme: AppTheme.dark(),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegistrationPage(),
      },
      home: const RegistrationPage(),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _submitting = false;
  final _emailFocus = FocusNode();
  bool _obscurePassword = true;
  static const int requiredUniqueChars = 1;

  @override
  void dispose() {
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _showEmailInUseDialog() async {
    const msg = 'Nije moguće koristiti ovaj email — već je u upotrebi.';
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Registracija'),
            IconButton(
              tooltip: 'Zatvori',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: const Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.saveAndValidate() ?? false;
    if (!ok) return;

    final v = _formKey.currentState!.value;

    setState(() => _submitting = true);
    try {
      final success = await AuthProvider.register(
        firstName: v['firstName'],
        lastName: v['lastName'],
        email: v['email'],
        password: v['password'],
      );
      setState(() => _submitting = false);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Račun je kreiran. Prijavite se.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
      // nema generičkog "registracija nije uspjela" — sve ide u catch
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;

      final s = e.toString();
      final is409 =
          RegExp(r'HTTP\s*409').hasMatch(s) ||
          s.contains('"status":409') ||
          s.toLowerCase().contains('conflict');

      if (is409) {
        final emailField = _formKey.currentState?.fields['email'];
        emailField?.invalidate('Email je već u upotrebi.');
        await _showEmailInUseDialog();
        emailField?.didChange('');
        FocusScope.of(context).requestFocus(_emailFocus);
        return;
      }

      // ostalo — generički popup
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Greška'),
              IconButton(
                tooltip: 'Zatvori',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: Text('Došlo je do greške.\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registracija')),
      body: Center(
        child: Card(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FormBuilderTextField(
                      name: 'firstName',
                      decoration: const InputDecoration(
                        labelText: 'First name *',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Username can not be empty.',
                        ),
                        FormBuilderValidators.minLength(
                          2,
                          errorText:
                              "Username can't be less than 2 characters.",
                        ),
                        FormBuilderValidators.maxLength(
                          50,
                          errorText:
                              "Username can't be more than 50 characters.",
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'lastName',
                      decoration: const InputDecoration(
                        labelText: 'Last name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Last name ne moze biti prazan.',
                        ),
                        FormBuilderValidators.minLength(
                          2,
                          errorText:
                              'Last name ne moze biti manje od dva karaktera.',
                        ),
                        FormBuilderValidators.maxLength(
                          50,
                          errorText:
                              "Last name can't be more than 50 characters.",
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'email',
                      focusNode: _emailFocus,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        // ⬇️ koristimo 'email' (malim slovom)
                        final f = _formKey.currentState?.fields['email'];
                        if (f?.hasError == true) f?.invalidate('');
                      },
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Email ne moze biti prazan.',
                        ),
                        FormBuilderValidators.email(
                          errorText:
                              'Unesite ispravan email (npr. korisnik@example.com).',
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'password',
                      obscureText: _obscurePassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Prikaži lozinku'
                              : 'Sakrij lozinku',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Password ne moze biti prazan.',
                        ),
                        FormBuilderValidators.minLength(
                          8,
                          errorText: 'Password mora imati najmanje 8 znakova.',
                        ),
                        (v) =>
                            (v == null ||
                                v.isEmpty ||
                                RegExp(r'\d').hasMatch(v))
                            ? null
                            : 'Password mora sadržavati barem jednu cifru.',
                        (v) =>
                            (v == null ||
                                v.isEmpty ||
                                RegExp(r'[a-z]').hasMatch(v))
                            ? null
                            : 'Password mora sadržavati barem jedno malo slovo.',
                        (v) =>
                            (v == null ||
                                v.isEmpty ||
                                RegExp(r'[A-Z]').hasMatch(v))
                            ? null
                            : 'Password mora sadržavati barem jedno VELIKO slovo.',
                        (v) =>
                            (v == null ||
                                v.isEmpty ||
                                RegExp(r'[^A-Za-z0-9]').hasMatch(v))
                            ? null
                            : 'Password mora sadržavati barem jedan specijalni znak.',
                        (v) {
                          if (v == null || v.isEmpty) return null;
                          final distinct = v.runes.toSet().length;
                          return distinct < requiredUniqueChars
                              ? 'Password mora imati najmanje $requiredUniqueChars različitih znakova.'
                              : null;
                        },
                      ]),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Registruj se'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/login'),
                      child: const Text('Imate već račun? Prijavite se'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
