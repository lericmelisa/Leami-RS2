import 'package:flutter/material.dart';
import 'package:leami_desktop/providers/article_category_provider.dart';
import 'package:leami_desktop/providers/article_provider.dart';
import 'package:leami_desktop/providers/auth_provider.dart';
import 'package:leami_desktop/providers/order_response_provider.dart';
import 'package:leami_desktop/providers/report_provider.dart';
import 'package:leami_desktop/providers/reservation_provider.dart';
import 'package:leami_desktop/providers/restaurant_info_provider.dart';
import 'package:leami_desktop/providers/review_provider.dart';
import 'package:leami_desktop/providers/user_provider.dart';
import 'package:leami_desktop/providers/user_role_provider.dart';
import 'package:leami_desktop/screens/main_menu_employee.dart';
import 'package:leami_desktop/screens/main_menu_screen.dart';
import 'package:provider/provider.dart';
import 'package:leami_desktop/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ArticleProvider>(
          create: (context) => ArticleProvider(),
        ),
        ChangeNotifierProvider<ArticleCategoryProvider>(
          create: (context) => ArticleCategoryProvider(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(),
        ),
        ChangeNotifierProvider<UserRoleProvider>(
          create: (context) => UserRoleProvider(),
        ),
        ChangeNotifierProvider<ReservationProvider>(
          create: (context) => ReservationProvider(),
        ),
        ChangeNotifierProvider<ReviewProvider>(
          create: (context) => ReviewProvider(),
        ),
        ChangeNotifierProvider<RestaurantInfoProvider>(
          create: (context) => RestaurantInfoProvider(),
        ),
        ChangeNotifierProvider<ReportProvider>(
          create: (context) => ReportProvider(),
        ),
        ChangeNotifierProvider<OrderResponseProvider>(
          create: (context) => OrderResponseProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark(),
      theme: AppTheme.dark(),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Center(
        child: Card(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16.00),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/leami_logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      icon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      icon: const Icon(Icons.lock),
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
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final pass = passwordController.text;

                      final success = await AuthProvider.login(email, pass);
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pogrešna lozinka ili korisnik.'),
                          ),
                        );
                        return;
                      }

                      final roleName = (AuthProvider.user?.role?.name ?? '')
                          .toLowerCase();

                      if (!mounted) return;

                      if (roleName == 'admin') {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const MainMenuScreen(),
                          ),
                        );
                      } else if (roleName == 'employee' ||
                          roleName == 'zaposlenik') {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const EmployeeMainMenuScreen(),
                          ),
                        );
                      } else {
                        // Ako nije ni admin ni employee — nema pristup desktop aplikaciji
                        await showDialog<void>(
                          context: context,
                          barrierDismissible:
                              true, // tap izvan dijaloga ga zatvara (opcionalno)
                          builder: (ctx) => AlertDialog(
                            titlePadding: const EdgeInsets.fromLTRB(
                              24,
                              20,
                              8,
                              0,
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Pristup odbijen'),
                                IconButton(
                                  tooltip: 'Zatvori',
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                            content: const Text(
                              'Samo administrator i zaposlenik mogu pristupiti ovoj aplikaciji.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
