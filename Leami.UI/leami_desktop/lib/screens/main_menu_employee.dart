import 'package:flutter/material.dart';
import 'package:leami_desktop/main.dart';
import 'package:leami_desktop/providers/auth_provider.dart';
import 'package:leami_desktop/screens/admin_screen.dart';
import 'package:leami_desktop/screens/employe_orders_screen.dart';
import 'package:leami_desktop/screens/employe_reservations_screen.dart';
import 'package:leami_desktop/screens/employe_screen.dart';
import 'package:leami_desktop/screens/reservations_list.dart';

class EmployeeMainMenuScreen extends StatefulWidget {
  const EmployeeMainMenuScreen({super.key});

  @override
  State<EmployeeMainMenuScreen> createState() => _EmployeeMainMenuScreenState();
}

class _EmployeeMainMenuScreenState extends State<EmployeeMainMenuScreen> {
  int _current = 0;

  // Stavke menija (naslovi/ikone + builderi za stranice)
  late final List<_MenuItem> _items = [
    _MenuItem(
      title: 'Narudžbe',
      icon: Icons.receipt_long,
      builder: () => const EmployeeOrdersScreen(),
    ),
    _MenuItem(
      title: 'Rezervacije',
      icon: Icons.event_note,
      builder: () => const EmployeeReservationsScreen(),
    ),
    _MenuItem(
      title: 'Profil',
      icon: Icons.verified_user,
      builder: () => EmployeeScreen(userId: AuthProvider.user!.id!),
    ),
  ];

  // Cache već izgrađenih stranica (lazy build)
  late final List<Widget?> _pagesCache = List<Widget?>.filled(
    _items.length,
    null,
  );

  Widget _buildPage(int index) {
    _pagesCache[index] ??= _items[index].builder();
    return _pagesCache[index]!;
  }

  Future<void> _logout(BuildContext context) async {
    // Employee najčešće ne mora čistiti sve provide-re kao admin;
    // Ako imaš specifične providere (npr. narudžbe/rezervacije), ovdje pozovi njihovo clear().

    await AuthProvider.logoutApi(); // nije fatalno ako padne
    AuthProvider.logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leami — Employee')),
      body: Row(
        children: [
          // Lijevi meni
          Container(
            width: 260,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Expanded(
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
                const Divider(),
                _SideTile(
                  title: 'Odjava',
                  icon: Icons.logout_rounded,
                  selected: false,
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),

          // Desni sadržaj – samo aktivna stranica
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(.06),
                  child: _buildPage(_current),
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
