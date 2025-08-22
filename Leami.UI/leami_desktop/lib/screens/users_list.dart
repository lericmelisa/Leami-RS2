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

  SearchResult<User>? users;
  SearchResult<UserRole>? roles;

  final Map<int, UserRole> roleMap = {};
  final TextEditingController searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  String? _currentRoleFilter = "Guest";

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
      roleMap.clear();
      for (var r in roles?.items ?? []) {
        if (r.id != null) roleMap[r.id!] = r;
      }
      setState(() {});
    } catch (e) {
      setState(() => _error = "Greška prilikom učitavanja rola: $e");
    }
  }

  Future<void> _loadUsers([Map<String, dynamic>? filter]) async {
    try {
      setState(() => _isLoading = true);
      users = await userProvider.get(filter: filter);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = "Greška prilikom učitavanja korisnika: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTopButtons(),
              const SizedBox(height: 16),
              _buildSearch(),
              const SizedBox(height: 16),
              Expanded(child: _buildResultView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.badge),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentRoleFilter == "Employee"
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("Upravljanje uposlenicima"),
            ),
            onPressed: () async {
              setState(() => _currentRoleFilter = "Employee");
              searchController.clear(); // Obriši pretragu
              await _loadUsers({"RoleName": "Employee"});
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentRoleFilter == "Guest"
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("Upravljanje gostima"),
            ),
            onPressed: () async {
              setState(() => _currentRoleFilter = "Guest");
              searchController.clear(); // Obriši pretragu
              await _loadUsers({"RoleName": "Guest"});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Row(
        children: [
          const Icon(Icons.search),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Pretraži korisnike po emailu, imenu ili prezimenu",
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Kombinuj RoleName i FTS filtere
              final filter = <String, dynamic>{"RoleName": _currentRoleFilter!};

              // Dodaj FTS samo ako nije prazan
              if (searchController.text.trim().isNotEmpty) {
                filter["FTS"] = searchController.text.trim();
              }

              await _loadUsers(filter);
            },

            child: const Text("Pretraži"),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final List<User> list = users?.items ?? const <User>[];
    if (list.isEmpty) {
      return Center(
        child: Text(
          searchController.text.isEmpty
              ? "Nema ${_currentRoleFilter?.toLowerCase()}a u sistemu."
              : "Nema rezultata za pretragu '${searchController.text}' u ${_currentRoleFilter?.toLowerCase()}ima.",
        ),
      );
    }

    // Ako makar jedan korisnik ima rolu Employee -> prikazujemo dodatne kolone
    final bool hasEmployees = list.any((u) => u.role?.name == "Employee");

    final columns = <DataColumn>[
      const DataColumn(label: Text('Ime')),
      const DataColumn(label: Text('Prezime')),
      const DataColumn(label: Text('Email')),
      const DataColumn(label: Text('Username')),
      const DataColumn(label: Text('Role')),
      if (hasEmployees) const DataColumn(label: Text('Job Title')),
      if (hasEmployees) const DataColumn(label: Text('Hire Date')),
      if (hasEmployees) const DataColumn(label: Text('Note')),
      const DataColumn(label: Text('Akcije')),
    ];

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              primary: true,
              child: SingleChildScrollView(
                primary: true,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columns: columns,
                    rows: list.map<DataRow>((u) {
                      final roleText = u.role?.name ?? 'N/A';

                      final cells = <DataCell>[
                        DataCell(Text(u.firstName ?? 'N/A')),
                        DataCell(Text(u.lastName ?? 'N/A')),
                        DataCell(Text(u.email ?? 'N/A')),
                        DataCell(Text(u.username ?? 'N/A')),
                        DataCell(Text(roleText)),
                        if (hasEmployees)
                          DataCell(
                            Text(
                              roleText == "Employee" ? (u.jobTitle ?? "-") : "",
                            ),
                          ),
                        if (hasEmployees)
                          DataCell(
                            Text(
                              roleText == "Employee"
                                  ? (u.hireDate
                                            ?.toIso8601String()
                                            .split("T")
                                            .first ??
                                        "-")
                                  : "",
                            ),
                          ),
                        if (hasEmployees)
                          DataCell(
                            Text(roleText == "Employee" ? (u.note ?? "-") : ""),
                          ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteUserDialog(u),
                          ),
                        ),
                      ];

                      return DataRow(
                        onSelectChanged: (_) async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailsScreen(user: u),
                            ),
                          );

                          // Ako je vraćen true, refreshuj listu
                          if (result == true) {
                            final filter = <String, dynamic>{
                              "RoleName": _currentRoleFilter!,
                            };

                            // Zadržaj pretragu ako postoji
                            if (searchController.text.trim().isNotEmpty) {
                              filter["FTS"] = searchController.text.trim();
                            }

                            await _loadUsers(filter);
                          }
                        },

                        cells: cells,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteUserDialog(User u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Brisanje korisnika"),
        content: const Text("Da li ste sigurni da želite obrisati korisnika?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await userProvider.delete(u.id);
                Navigator.of(ctx).pop();
                final filter = <String, dynamic>{
                  "RoleName": _currentRoleFilter!,
                };

                // Zadržaj pretragu ako postoji
                if (searchController.text.trim().isNotEmpty) {
                  filter["FTS"] = searchController.text.trim();
                }

                await _loadUsers(filter);
              } catch (e) {
                Navigator.of(ctx).pop();
                _showErrorDialog("Greška prilikom brisanja: $e");
              }
            },
            child: const Text("Izbriši"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Greška"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Ok"),
          ),
        ],
      ),
    );
  }
}
