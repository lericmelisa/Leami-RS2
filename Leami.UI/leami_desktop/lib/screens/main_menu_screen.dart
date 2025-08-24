import 'package:flutter/material.dart';
// === tvoji ekrani (prema listi fajlova) ===
import 'package:leami_desktop/screens/restaurant_info_screen.dart'; // Opšte postavke
import 'package:leami_desktop/screens/article_categories_switcher.dart'; // Upravljanje jelovnikom (artikli/kategorije)
import 'package:leami_desktop/screens/users_list.dart'; // Upravljanje računima (korisnici/uloge)
import 'package:leami_desktop/screens/reservations_list.dart'; // Rezervacije
import 'package:leami_desktop/screens/review_list.dart'; // Recenzije
import 'package:leami_desktop/screens/home_screen.dart'; // Uvid u izvještaje (placeholder)

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _current = 0;

  // Definišemo stavke menija
  late final List<_MenuItem> _items = [
    _MenuItem(
      title: 'Opšte postavke',
      icon: Icons.settings,
      builder: () => const RestaurantInfoListScreen(),
    ),
    _MenuItem(
      title: 'Upravljanje jelovnikom',
      icon: Icons.restaurant_menu,
      builder: () => const ArticlesCategoriesSwitcher(),
    ),
    _MenuItem(
      title: 'Upravljanje računima',
      icon: Icons.group,
      builder: () => const UsersList(),
    ),
    _MenuItem(
      title: 'Rezervacije',
      icon: Icons.event_note,
      builder: () => const ReservationList(),
    ),
    _MenuItem(
      title: 'Recenzije',
      icon: Icons.reviews,
      builder: () => const ReviewListScreen(),
    ),
    _MenuItem(
      title: 'Uvid u izvještaje',
      icon: Icons.bar_chart,
      builder: () => const HomeScreen(),
    ),
  ];

  // Mjesto za keširanje izgrađenih ekrana
  late final List<Widget?> _pagesCache = List<Widget?>.filled(
    _items.length,
    null,
  );

  // Funkcija za lazy inicijalizaciju pojedinog ekrana
  Widget _buildPage(int index) {
    if (_pagesCache[index] == null) {
      _pagesCache[index] = _items[index].builder();
    }
    return _pagesCache[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leami')),
      body: Row(
        children: [
          // Lijevi fiksni meni
          Container(
            width: 260,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final sel = i == _current;
                final it = _items[i];
                return _SideTile(
                  title: it.title,
                  icon: it.icon,
                  selected: sel,
                  onTap: () => setState(() => _current = i),
                );
              },
            ),
          ),

          // Desni dio – sadržaj koji se mijenja
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(.06),
                  child: IndexedStack(
                    index: _current,
                    children: List.generate(
                      _items.length,
                      (i) => _buildPage(i),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget Function() builder;
  _MenuItem({required this.title, required this.icon, required this.builder});
}

class _SideTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SideTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Theme.of(context).colorScheme.primary.withOpacity(.18)
        : Colors.transparent;
    final fg = selected
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).textTheme.bodyMedium?.color;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: fg,
                  ),
                ),
              ),
              if (selected) const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
