import 'package:flutter/material.dart';
import 'package:leami_desktop/models/user.dart';
import 'package:leami_desktop/models/user_role.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/providers/user_provider.dart';
import 'package:leami_desktop/providers/user_role_provider.dart';
import 'package:leami_desktop/screens/user_details_screen.dart';
import 'package:provider/provider.dart';

class UsersList extends StatefulWidget {
  const UsersList({super.key});

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  late UserProvider userProvider;
  late UserRoleProvider userRoleProvider;

  // Kontroleri za skrol
  final _hScrollCtrl = ScrollController(); // horizontalni
  final _vScrollCtrl = ScrollController(); // vertikalni

  SearchResult<User>? users;
  SearchResult<UserRole>? roles;

  final TextEditingController searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  String _currentRoleFilter = "Guest";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProvider = context.read<UserProvider>();
      userRoleProvider = context.read<UserRoleProvider>();
      _initData();
    });
  }

  Future<void> _initData() async {
    await _loadRoles();
    await _loadUsers({"RoleName": _currentRoleFilter});
  }

  Future<void> _loadRoles() async {
    try {
      roles = await userRoleProvider.get();
      setState(() {});
    } catch (e) {
      setState(() => _error = "Greška pri učitavanju rola: $e");
    }
  }

  Future<void> _loadUsers([Map<String, dynamic>? filter]) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      users = await userProvider.get(filter: filter);
    } catch (e) {
      _error = "Greška pri učitavanju korisnika: $e";
      debugPrint("[_loadUsers] error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _hScrollCtrl.dispose();
    _vScrollCtrl.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 720; // prag za prelome
            const gutter = 16.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopButtonsResponsive(isNarrow),
                    const SizedBox(height: gutter),
                    _buildSearchResponsive(isNarrow),
                    const SizedBox(height: gutter),
                    _buildTableResponsive(constraints),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------- Responsive gornji dugmići ----------
  Widget _buildTopButtonsResponsive(bool isNarrow) {
    final btnEmployee = ElevatedButton(
      onPressed: () => _onRoleTap("Employee"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: _currentRoleFilter == "Employee"
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
      ),
      child: const Text('Upravljanje uposlenicima'),
    );

    final btnGuest = ElevatedButton(
      onPressed: () => _onRoleTap("Guest"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: _currentRoleFilter == "Guest"
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
      ),
      child: const Text('Upravljanje gostima'),
    );

    if (isNarrow) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(width: double.infinity, child: btnEmployee),
          SizedBox(width: double.infinity, child: btnGuest),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: btnEmployee),
        const SizedBox(width: 8),
        Expanded(child: btnGuest),
      ],
    );
  }

  // ---------- Responsive search ----------
  Widget _buildSearchResponsive(bool isNarrow) {
    final searchField = Expanded(
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Pretraži korisnike po emailu, imenu ili prezimenu',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
        ),
        onSubmitted: (_) => _onSearch(),
      ),
    );

    final searchBtn = ElevatedButton.icon(
      onPressed: _onSearch,
      icon: const Icon(Icons.search),
      label: const Text('Pretraži'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [searchField]),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: searchBtn),
        ],
      );
    }

    return Row(children: [searchField, const SizedBox(width: 8), searchBtn]);
  }

  Future<void> _onRoleTap(String role) async {
    setState(() => _currentRoleFilter = role);
    searchController.clear();
    await _loadUsers({"RoleName": role});
  }

  Future<void> _onSearch() async {
    final text = searchController.text.trim();
    final filter = {"RoleName": _currentRoleFilter};
    if (text.isNotEmpty) filter["FTS"] = text;
    await _loadUsers(filter);
    searchController.clear();
  }

  // ---------- Responsive tabela ----------
  Widget _buildTableResponsive(BoxConstraints constraints) {
    final list = users?.items ?? [];
    if (list.isEmpty) {
      return Center(child: Text('Nema korisnika za $_currentRoleFilter'));
    }

    final hasEmployees = list.any((u) => u.role?.name == "Employee");

    // Minimalna širina sadržaja (samo za uske ekrane); na širokim koristimo pun viewport
    final double contentMinWidth = hasEmployees ? 980 : 760;

    final columns = <DataColumn>[
      const DataColumn(label: Text('Ime')),
      const DataColumn(label: Text('Prezime')),
      const DataColumn(label: Text('Email')),
      const DataColumn(label: Text('Role')),
      if (hasEmployees) const DataColumn(label: Text('Job Title')),
      if (hasEmployees) const DataColumn(label: Text('Hire Date')),
      if (hasEmployees) const DataColumn(label: Text('Note')),
      const DataColumn(label: Text('Akcije')),
    ];

    final rows = list.map((u) {
      final roleText = u.role?.name ?? 'N/A';
      return DataRow(
        cells: [
          DataCell(Text(u.firstName ?? '')),
          DataCell(Text(u.lastName ?? '')),
          DataCell(
            ConstrainedBox(
              // širi limit za email na širokom ekranu
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth >= contentMinWidth ? 360 : 260,
              ),
              child: Text(
                u.email ?? '',
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ),
          DataCell(Text(roleText)),
          if (hasEmployees)
            DataCell(Text(roleText == 'Employee' ? (u.jobTitle ?? '-') : '')),
          if (hasEmployees)
            DataCell(
              Text(
                roleText == 'Employee'
                    ? (u.hireDate?.toIso8601String().split('T').first ?? '-')
                    : '',
              ),
            ),
          if (hasEmployees)
            DataCell(Text(roleText == 'Employee' ? (u.note ?? '-') : '')),
          DataCell(
            Wrap(
              spacing: 6,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () => _onEdit(u),
                  tooltip: 'Uredi',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _showDelete(u),
                  tooltip: 'Obriši',
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();

    // Ako staje u viewport — nema horizontalnog skrola; inače uključujemo horizontalni
    final double viewportW = constraints.maxWidth;
    final bool needsHScroll = contentMinWidth > viewportW;
    final double tableWidth = needsHScroll ? contentMinWidth : viewportW;

    final tableWidget = SizedBox(
      width: tableWidth,
      child: SingleChildScrollView(
        controller: _vScrollCtrl,
        scrollDirection: Axis.vertical,
        primary: false,
        child: DataTable(
          columnSpacing: 18,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 56,
          headingRowHeight: 48,
          showCheckboxColumn: false,
          columns: columns,
          rows: rows,
        ),
      ),
    );

    return Card(
      child: needsHScroll
          ? Scrollbar(
              controller: _hScrollCtrl,
              thumbVisibility: true,
              interactive: true,
              notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _hScrollCtrl,
                scrollDirection: Axis.horizontal,
                primary: false,
                child: tableWidget, // šire od ekrana -> skrol
              ),
            )
          : tableWidget, // staje u ekran -> bez horizontalnog skrola
    );
  }

  Future<void> _onEdit(User u) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UserDetailsScreen(user: u)),
    );
    if (res == true) _initData();
  }

  void _showDelete(User u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brisanje korisnika'),
        content: const Text('Potvrdi brisanje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await userProvider.delete(u.id!);
              _initData();
            },
            child: const Text('Izbriši'),
          ),
        ],
      ),
    );
  }
}
