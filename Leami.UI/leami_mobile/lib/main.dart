import 'package:flutter/material.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/models/stripe_service.dart';
import 'package:leami_mobile/models/user.dart';
import 'package:leami_mobile/providers/article_category_provider.dart';
import 'package:leami_mobile/providers/article_provider.dart';
import 'package:leami_mobile/providers/auth_provider.dart';
import 'package:leami_mobile/providers/cart_provider.dart';
import 'package:leami_mobile/providers/notification_provider.dart';
import 'package:leami_mobile/providers/order_provider.dart';
import 'package:leami_mobile/providers/reservation_provider.dart';
import 'package:leami_mobile/providers/restaurant_info_provider.dart';
import 'package:leami_mobile/providers/review_provider.dart';
import 'package:leami_mobile/providers/stomp_provider.dart';
import 'package:leami_mobile/providers/user_provider.dart';
import 'package:leami_mobile/providers/user_role_provider.dart';
import 'package:leami_mobile/screens/guest_articles_screen.dart';
import 'package:leami_mobile/theme/theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StripeService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StompService()),
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
        ChangeNotifierProvider<CartProvider>(
          create: (context) => CartProvider(),
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (context) => OrderProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (context) => NotificationProvider(),
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

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late SearchResult<User> _users;
  late UserProvider _userProvider;

  @override
  Widget build(BuildContext context) {
    _userProvider = context.read<UserProvider>();

    return Scaffold(
      // Scaffold is a layout structure that provides a default app bar, title,
      appBar: AppBar(title: Text('Login Page')),
      body: Center(
        child: Card(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16.00),
              child: Column(
                children: [
                  Image.network(
                    "https://fit.ba/content/763cbb87-718d-4eca-a991-343858daf424",
                    width: 200,
                    height: 200,
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Username',
                      icon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      icon: Icon(Icons.password),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final pass = passwordController.text;
                      final email = emailController.text;
                      print(pass);
                      print(email);
                      // 1) login
                      final success = await AuthProvider.login(email, pass);
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pogrešna lozinka ili korisnik.'),
                          ),
                        );
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const GuestArticlesScreen(),
                          ),
                        );
                        return;
                      }

                      try {
                        // 2) dohvat korisnika po e-mailu
                        _users = await _userProvider.get(
                          filter: {"FTS": email},
                        );
                        User user = _users.items!.first;
                        print("DOHVACENI USER JE: ${user.firstName}");

                        // 3) provjera role
                        if ((user.role?.name ?? '') != 'Administrator') {
                          // nije admin → poruka i out
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Pristup odbijen'),
                              content: const Text(
                                'Samo administrator može pristupiti ovoj aplikaciji.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        // 4) sve OK → idi na glavni ekran
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const GuestArticlesScreen(),
                          ),
                        );
                      } catch (e) {
                        // neuspjeh pri dohvat
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Greška pri dohvatu korisnika: $e'),
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
