import 'package:flutter/material.dart';
import 'package:leami_mobile/screens/accessibility_settings.dart';
import 'package:provider/provider.dart';
import 'package:leami_mobile/providers/cart_provider.dart';
import 'package:leami_mobile/screens/payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  void _showRemoveDialog(
    BuildContext context,
    int itemId,
    String itemName,
    CartProvider cart,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ukloni artikal'),
          content: Text('Da li želite ukloniti "$itemName" iz korpe?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Otkaži'),
            ),
            TextButton(
              onPressed: () {
                cart.removeItem(itemId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$itemName je uklonjen iz korpe'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Ukloni'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final entries = cart.items.entries.toList();

    final settings = context.watch<AccessibilitySettings>();
    final bool bigUi = settings.largeControls || settings.textScale >= 1.4;

    final double toolbarHeight = bigUi ? 64 : kToolbarHeight;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: bigUi ? 72 : kToolbarHeight,
        title: const Text('Korpa'),
        elevation: 0,
        actions: entries.isNotEmpty
            ? [
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Stack(
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Očisti korpu'),
                              ),
                              Positioned(
                                right: -8,
                                top: -8,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Zatvori',
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ],
                          ),
                          content: const Text(
                            'Da li želite ukloniti sve artikle iz korpe?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Otkaži'),
                            ),
                            TextButton(
                              onPressed: () {
                                cart.clear();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Korpa je očišćena'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                              child: const Text('Očisti'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Očisti sve'),
                ),
              ]
            : null,
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Korpa je prazna',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dodajte artikle da biste nastavili',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Nastavi kupovinu'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header sa informacijama
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entries.length} ${entries.length == 1 ? "artikal" : "artikala"} u korpi',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // Lista artikala
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final id = entries[i].key;
                      final item = entries[i].value;
                      final totalPrice = item.price * item.quantity;

                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Informacije o proizvodu (BEZ SLIKE)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.price.toStringAsFixed(2)} KM po komadu',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Ukupno: ${totalPrice.toStringAsFixed(2)} KM',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Kontrole količine + delete
                              Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Tooltip(
                                          message: 'Smanji količinu artikla',
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              onTap: () {
                                                final newQty =
                                                    item.quantity - 1;
                                                if (newQty > 0) {
                                                  cart.updateQuantity(
                                                    id,
                                                    newQty,
                                                  );
                                                } else {
                                                  _showRemoveDialog(
                                                    context,
                                                    id,
                                                    item.name,
                                                    cart,
                                                  );
                                                }
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 30,
                                          ),
                                          child: Text(
                                            '${item.quantity}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Tooltip(
                                          message: 'Povećaj količinu artikla',
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              onTap: () {
                                                cart.addItem(
                                                  id,
                                                  item.name,
                                                  item.price,
                                                );
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Tooltip(
                                    message: 'Ukloni artikal iz korpe',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _showRemoveDialog(
                                          context,
                                          id,
                                          item.name,
                                          cart,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red.shade400,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom section sa ukupnom cijenom
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Broj artikala
                        if (bigUi)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Broj artikala:',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${cart.totalItems}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Broj artikala:',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '${cart.totalItems}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 4),

                        // Ukupna cijena
                        if (bigUi)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ukupna cijena:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${cart.totalPrice.toStringAsFixed(2)} KM',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ukupna cijena:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${cart.totalPrice.toStringAsFixed(2)} KM',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaymentScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Nastavi na plaćanje',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
