import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:leami_mobile/models/restaurant_info.dart';
import 'package:leami_mobile/providers/restaurant_info_provider.dart';

import 'package:provider/provider.dart';

import 'restaurant_info_details.dart';

class RestaurantInfoListScreen extends StatefulWidget {
  const RestaurantInfoListScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantInfoListScreen> createState() =>
      _RestaurantInfoListScreenState();
}

class _RestaurantInfoListScreenState extends State<RestaurantInfoListScreen> {
  late RestaurantInfoProvider _provider;
  RestaurantInfo? _info;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<RestaurantInfoProvider>();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await _provider.getInfo();
      setState(() => _info = info);
    } catch (e) {
      // Ako nema zapisa u bazi, getInfo može baciti exception ili vratiti null
      if (e.toString().contains('Nema postavki restorana')) {
        setState(() => _info = null);
      } else {
        setState(() => _error = 'Greška pri učitavanju: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Uint8List? _decodeImage(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      final pure = b64.contains(',') ? b64.split(',').last : b64;
      return base64Decode(pure);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    // Ako _info == null, ponudi dugme za kreiranje
    if (_info == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const SizedBox.shrink(),
        ),
        body: Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Kreiraj osnovne postavke'),
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const RestaurantInfoDetailsScreen(info: null),
                ),
              );
              if (created == true) {
                _loadInfo();
              }
            },
          ),
        ),
      );
    }

    // Inače, imamo već postojeće postavke
    final imageBytes = _decodeImage(_info!.restaurantImage);

    return Scaffold(
      appBar: AppBar(title: const Text('Postavke restorana')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageBytes != null)
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Image.memory(imageBytes, fit: BoxFit.contain),
                )
              else
                Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.restaurant, size: 48)),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _info!.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _info!.description ?? '-',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(height: 32),
                      Text('Adresa: ${_info!.address ?? '-'}'),
                      Text('Telefon: ${_info!.phone ?? '-'}'),
                      const SizedBox(height: 8),
                      Text(
                        'Radno vrijeme: ${_info!.openingTime} – ${_info!.closingTime}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantInfoDetailsScreen(info: _info),
            ),
          );
          if (updated == true) _loadInfo();
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
