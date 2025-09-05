import 'package:flutter/material.dart';
import 'package:leami_desktop/models/order_item_response.dart';
import 'package:provider/provider.dart';

// Ako imaš različit path/ime providera/modela, prilagodi ove import-e:
import 'package:leami_desktop/providers/order_response_provider.dart';
import 'package:leami_desktop/models/search_result.dart';
import 'package:leami_desktop/models/order_response.dart';

class EmployeeOrdersScreen extends StatefulWidget {
  const EmployeeOrdersScreen({super.key});

  @override
  State<EmployeeOrdersScreen> createState() => _EmployeeOrdersScreenState();
}

class _EmployeeOrdersScreenState extends State<EmployeeOrdersScreen> {
  bool _loading = true;
  String? _error;
  List<OrderResponse> _orders = [];

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
      final provider = context.read<OrderResponseProvider>();

      // Provider može vratiti SearchResult<OrderResponse> ili List<OrderResponse>.
      final res = await provider.get(); // bez filtera => sve narudžbe
      List<OrderResponse> list;

      list = (res.items ?? []).toList();

      // Sortiraj najnovije prve
      list.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      setState(() => _orders = list);
    } catch (e) {
      setState(() => _error = 'Greška pri učitavanju narudžbi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Narudžbe')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Narudžbe')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Narudžbe'),
        actions: [
          IconButton(
            tooltip: 'Osvježi',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _orders.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nema narudžbi za prikaz.')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _orders.length,
                itemBuilder: (_, i) => _OrderCard(order: _orders[i]),
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
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Narudžba #${order.orderId}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              // “kada je naručeno” + metoda plaćanja
              '$dateStr u $timeStr ',
            ),
          ),
          trailing: Text(
            '$total KM',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  for (final it in order.orderItems)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _lineForItem(it),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${it.unitPrice.toStringAsFixed(2)} KM'),
                          const SizedBox(width: 12),
                          Text(
                            '${it.total.toStringAsFixed(2)} KM',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Ukupno: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${order.totalAmount.toStringAsFixed(2)} KM',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Preferiraj naziv artikla iz Article, fallback na ID
  String _lineForItem(OrderItemResponse it) {
    final artName = it.article.articleName.trim();
    final label = (artName != null && artName.isNotEmpty)
        ? artName
        : 'Artikal #${it.articleId}';
    return '$label  •  Količina: ${it.quantity}';
  }

  Widget _statusChip(String text) {
    Color? bg;
    Color? fg = Colors.black87;
    switch (text.toLowerCase()) {
      case 'completed':
      case 'završeno':
      case 'done':
        bg = Colors.green.shade100;
        break;
      case 'cancelled':
      case 'otkazano':
        bg = Colors.red.shade100;
        break;
      case 'pending':
      case 'u toku':
      default:
        bg = Colors.amber.shade100;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  String _fmt2(int x) => x.toString().padLeft(2, '0');
  String _fmtDate(DateTime d) => '${_fmt2(d.day)}.${_fmt2(d.month)}.${d.year}.';
  String _fmtTime(DateTime d) => '${_fmt2(d.hour)}:${_fmt2(d.minute)}';
}
