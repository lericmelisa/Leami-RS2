import 'package:flutter/material.dart';
import 'package:leami_mobile/providers/order_response_provider.dart';
import 'package:provider/provider.dart';
import '../models/order_response.dart';
import '../models/search_result.dart';

class OrderHistoryScreen extends StatefulWidget {
  final int userId;

  const OrderHistoryScreen({super.key, required this.userId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late OrderResponseProvider _orderProvider;
  SearchResult<OrderResponse>? _orders;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderProvider = context.read<OrderResponseProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Pokušaj server-side filter (ako backend uvede UserId na search objektu)
      final res = await _orderProvider.get(filter: {"UserId": widget.userId});

      setState(() {
        _orders = res;
      });
    } catch (e) {
      setState(() => _error = 'Greška pri učitavanju: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historija narudžbi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    final items = _orders?.items ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Historija narudžbi')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nema narudžbi za prikaz.')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (_, i) => _OrderCard(order: items[i]),
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderResponse order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateStr = _fmtDate(order.orderDate);
    final timeStr = _fmtTime(order.orderDate);
    final total = order.totalAmount.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          title: Text(
            'Narudžba',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '$dateStr u $timeStr  •  ${order.paymentMethod == 'cod'
                ? 'Keš'
                : order.paymentMethod == 'stripe'
                ? 'Kartično plaćanje'
                : order.paymentMethod}',
          ),
          trailing: Text(
            '$total KM',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }

  String _fmt2(int x) => x.toString().padLeft(2, '0');

  String _fmtDate(DateTime d) => '${_fmt2(d.day)}.${_fmt2(d.month)}.${d.year}.';

  String _fmtTime(DateTime d) => '${_fmt2(d.hour)}:${_fmt2(d.minute)}';
}
