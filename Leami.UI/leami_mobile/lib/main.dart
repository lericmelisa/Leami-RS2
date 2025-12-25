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
import 'package:leami_mobile/screens/accessibility_settings.dart';
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
        ChangeNotifierProvider(create: (_) => AccessibilitySettings()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AccessibilitySettings>();
    final baseTheme = AppTheme.dark();
    final contrastTheme = settings.highContrast
        ? baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: Colors.amberAccent, // veći kontrast
              onPrimary: Colors.black,
              surface: const Color(0xFF000000),
              onSurface: Colors.white,
              onSurfaceVariant: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF000000),
            canvasColor: const Color(0xFF000000),
            cardTheme: baseTheme.cardTheme.copyWith(
              color: const Color(0xFF000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white, width: 1.5),
              ),
              elevation: 0,
            ),
            inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
              fillColor: const Color(0xFF000000),
              hintStyle: const TextStyle(color: Colors.white70),
              labelStyle: const TextStyle(color: Colors.white),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.amberAccent,
                  width: 2.0,
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.amberAccent),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            dividerColor: Colors.white38,
          )
        : baseTheme;
    ThemeData themed = contrastTheme;

    if (settings.largeControls) {
      themed = _applyLargeControls(themed);
    }

    final spacedTextTheme = buildSpacedTextTheme(
      themed.textTheme,
      settings.lineHeight,
      settings.letterSpacing,
      settings.boldText,
    );
    final theme = themed.copyWith(
      textTheme: spacedTextTheme,
      primaryTextTheme: spacedTextTheme,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: theme,
      theme: theme,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegistrationPage(),
      },
      home: const RegistrationPage(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(settings.textScale),
          ),
          child: child!,
        );
      },
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

TextTheme buildSpacedTextTheme(
  TextTheme base,
  double lineHeightFactor,
  double letterSpacingDelta,
  bool boldText,
) {
  TextStyle? applyTo(TextStyle? style) {
    if (style == null) return null;
    return style.copyWith(
      height: (style.height ?? 1.0) * lineHeightFactor,
      letterSpacing: (style.letterSpacing ?? 0.0) + letterSpacingDelta,
      fontWeight: boldText ? FontWeight.w900 : style.fontWeight,
    );
  }

  return base.copyWith(
    displayLarge: applyTo(base.displayLarge),
    displayMedium: applyTo(base.displayMedium),
    displaySmall: applyTo(base.displaySmall),
    headlineLarge: applyTo(base.headlineLarge),
    headlineMedium: applyTo(base.headlineMedium),
    headlineSmall: applyTo(base.headlineSmall),
    titleLarge: applyTo(base.titleLarge),
    titleMedium: applyTo(base.titleMedium),
    titleSmall: applyTo(base.titleSmall),
    bodyLarge: applyTo(base.bodyLarge),
    bodyMedium: applyTo(base.bodyMedium),
    bodySmall: applyTo(base.bodySmall),
    labelLarge: applyTo(base.labelLarge),
    labelMedium: applyTo(base.labelMedium),
    labelSmall: applyTo(base.labelSmall),
  );
}

ThemeData _applyLargeControls(ThemeData base) {
  const double bigIconSize = 28.0;

  final IconThemeData enlargedIconTheme = base.iconTheme.copyWith(
    size: bigIconSize,
  );
  return base.copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: base.colorScheme.primary,
        foregroundColor: base.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(80, 56), // ~48x48 tap target
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: base.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(12),
        minimumSize: const Size(48, 48),
      ),
    ),
    iconTheme: enlargedIconTheme,
    appBarTheme: base.appBarTheme.copyWith(
      iconTheme: (base.appBarTheme.iconTheme ?? enlargedIconTheme).copyWith(
        size: bigIconSize,
      ),
      actionsIconTheme: (base.appBarTheme.actionsIconTheme ?? enlargedIconTheme)
          .copyWith(size: bigIconSize),
    ),
  );
}
