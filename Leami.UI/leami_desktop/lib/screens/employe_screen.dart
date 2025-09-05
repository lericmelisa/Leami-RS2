import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:leami_desktop/models/user.dart';
import 'package:leami_desktop/providers/auth_provider.dart';
import 'package:leami_desktop/providers/user_provider.dart';
import 'package:leami_desktop/screens/admin_details_screen.dart';
import 'package:leami_desktop/screens/employe_details_screen.dart';
import 'package:provider/provider.dart';

class EmployeeScreen extends StatefulWidget {
  final int userId;
  const EmployeeScreen({super.key, required this.userId});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  User? _user;
  bool _loading = true;
  String? _error;
  final me = AuthProvider.user;

  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userProvider = context.read<UserProvider>();
      _reloadFromBackend();
    });
    final jobTitle = (me?.jobTitle?.trim().isNotEmpty == true)
        ? me!.jobTitle!
        : '-';
  }

  Future<void> _reloadFromBackend() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fresh = await _userProvider.getById(widget.userId);
      if (!mounted) return;
      setState(() => _user = fresh);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Greška pri učitavanju: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil zaposlenika')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil zaposlenika')),
        body: Center(child: Text(_error!)),
      );
    }
    final u = _user!;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil zaposlenika')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToEdit,
        icon: const Icon(Icons.edit),
        label: const Text('Uredi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ProfileAvatar(imageBase64: u.userImage),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim(),
                            style: Theme.of(context).textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            u.email ?? '-',
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(
                              label: Text(u.role?.name ?? '—'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Osnovni podaci',
              items: [
                _InfoRow(label: 'Ime', value: u.firstName ?? '-'),
                _InfoRow(label: 'Prezime', value: u.lastName ?? '-'),
                _InfoRow(label: 'Email', value: u.email ?? '-'),
                _InfoRow(label: 'Telefon', value: u.phoneNumber ?? '-'),
                _InfoRow(label: 'Uloga', value: u.role?.name ?? '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToEdit() async {
    if (_user == null) return;
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EmployeDetailsScreen(user: _user)),
    );
    if (res == true && mounted) {
      await _reloadFromBackend();
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageBase64;
  const _ProfileAvatar({required this.imageBase64});

  @override
  Widget build(BuildContext context) {
    final img = imageBase64;

    if (img != null && img.isNotEmpty) {
      try {
        final pure = img.contains(',') ? img.split(',').last : img;
        final bytes = const Base64Decoder().convert(pure);
        return CircleAvatar(radius: 40, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    }
    return const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 32));
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            ...items.expand((row) => [row, const Divider(height: 20)]),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiLine;
  const _InfoRow({
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyleLabel = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor);
    final textStyleValue = Theme.of(context).textTheme.bodyLarge;

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = constraints.maxWidth >= 600
            ? 200.0
            : (constraints.maxWidth >= 420 ? 160.0 : 120.0);
        return Row(
          crossAxisAlignment: multiLine
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(label, style: textStyleLabel),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: textStyleValue,
                maxLines: multiLine ? null : 1,
                overflow: multiLine
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
