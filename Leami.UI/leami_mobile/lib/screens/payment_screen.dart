import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:leami_mobile/models/order.dart';
import 'package:leami_mobile/models/order_item.dart';
import 'package:leami_mobile/models/review.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/providers/stripe_service.dart';
import 'package:leami_mobile/providers/auth_provider.dart';
import 'package:leami_mobile/providers/order_provider.dart';
import 'package:leami_mobile/providers/review_provider.dart';
import 'package:leami_mobile/screens/guest_review_screen.dart';
import 'package:provider/provider.dart';
import 'package:leami_mobile/providers/cart_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'stripe';

  late OrderProvider orderpr;
  late ReviewProvider reviewProvider;

  SearchResult<Review>? reviews;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    orderpr = Provider.of<OrderProvider>(context, listen: false);
    reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    loadreviews();
  }

  loadreviews() async {
    reviews = await reviewProvider.get();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final totalAmount = cart.totalPrice;

    return Scaffold(
      appBar: AppBar(title: const Text('Plaćanje'), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pregled narudžbe
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pregled narudžbe',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Divider(height: 20),
                          ...cart.itemsList.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.name} x ${item.quantity}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    '${item.totalPrice.toStringAsFixed(2)} KM',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ukupno:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${totalAmount.toStringAsFixed(2)} KM',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Način plaćanja
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Način plaćanja',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Kartica (Stripe)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedPaymentMethod == 'stripe'
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: RadioListTile<String>(
                              value: 'stripe',
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) => setState(
                                () => _selectedPaymentMethod = value!,
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kartica',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Platite kreditnom ili debitnom karticom',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Plaćanje kešom
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedPaymentMethod == 'cod'
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: RadioListTile<String>(
                              value: 'cod',
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) => setState(
                                () => _selectedPaymentMethod = value!,
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.payments_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Gotovina',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Platite kešom prilikom preuzimanja',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Info o sigurnosti
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Vaše podatke štitimo najnovijim sigurnosnim tehnologijama',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dugme za plaćanje
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _isProcessing || cart.items.isEmpty
                        ? null
                        : () => _onPayPressed(context, cart),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Obrađujem plaćanje...'),
                            ],
                          )
                        : Text(
                            _selectedPaymentMethod == 'stripe'
                                ? 'Plati ${totalAmount.toStringAsFixed(2)} KM'
                                : 'Potvrdi narudžbu',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (_selectedPaymentMethod == 'stripe') ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Powered by Stripe',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NOVO: handler koji otvara confirm modal prije stvarnog plaćanja
  Future<void> _onPayPressed(BuildContext context, CartProvider cart) async {
    final confirmed = await _showConfirmOrderDialog(
      context,
      amount: cart.totalPrice,
      isStripe: _selectedPaymentMethod == 'stripe',
    );
    if (confirmed != true) return;
    await _processPayment(context, cart);
  }

  // NOVO: confirm modal sa X u gornjem desnom uglu
  Future<bool?> _showConfirmOrderDialog(
    BuildContext context, {
    required double amount,
    required bool isStripe,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Potvrda narudžbe',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Zatvori',
                splashRadius: 18,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
          content: Text(
            'Jeste li sigurni da želite zaključiti narudžbu?\n'
            '${isStripe ? 'Način plaćanja: kartica (Stripe)\n' : 'Način plaćanja: keš\n'}'
            'Iznos: ${amount.toStringAsFixed(2)} KM',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Odustani'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(isStripe ? 'Plati' : 'Zaključi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPayment(BuildContext context, CartProvider cart) async {
    setState(() => _isProcessing = true);
    dev.log(
      'PAYMENT START: method=$_selectedPaymentMethod, total=${cart.totalPrice}',
      name: 'PAY',
    );

    try {
      if (_selectedPaymentMethod == 'stripe') {
        dev.log('Calling StripeService.processPayment...', name: 'PAY');

        // Timeout kao sigurnosna mreža da ne visi beskonačno
        final success = await StripeService.processPayment(
          amount: cart.totalPrice,
          currency: 'usd', // uskladi s backend-om
        ).timeout(const Duration(seconds: 60));

        dev.log('Stripe returned: $success', name: 'PAY');

        if (!success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Plaćanje otkazano.')));
          if (mounted) setState(() => _isProcessing = false);
          return; // bez ordera
        }

        // --- KREIRAJ NARUDŽBU ---
        final orderRequest = OrderRequest(
          userId: AuthProvider.user!.id,
          orderDate: DateTime.now(),
          totalAmount: cart.totalPrice,
          paymentMethod: _selectedPaymentMethod,
          orderItems: cart.itemsList
              .map(
                (item) => OrderItemRequest(
                  articleId: item.id,
                  quantity: item.quantity,
                  unitPrice: item.price,
                ),
              )
              .toList(),
        );

        dev.log('Creating order via API...', name: 'PAY');
        await orderpr.insert(orderRequest).timeout(const Duration(seconds: 25));
        dev.log('Order created OK', name: 'PAY');

        // --- VAŽNO: spusti spinner PRIJE dijaloga/navigacije ---
        if (mounted) setState(() => _isProcessing = false);

        _showPaymentSuccess(context, cart);
        _navigateToReviewIfAny(context);
      } else if (_selectedPaymentMethod == 'cod') {
        // Kreiraj isti request i kod keša
        final orderRequest = OrderRequest(
          userId: AuthProvider.user!.id,
          orderDate: DateTime.now(),
          totalAmount: cart.totalPrice,
          paymentMethod: _selectedPaymentMethod,
          orderItems: cart.itemsList
              .map(
                (item) => OrderItemRequest(
                  articleId: item.id,
                  quantity: item.quantity,
                  unitPrice: item.price,
                ),
              )
              .toList(),
        );

        dev.log('Creating order via API (COD)...', name: 'PAY');
        await orderpr.insert(orderRequest).timeout(const Duration(seconds: 25));
        dev.log('Order created OK (COD)', name: 'PAY');

        if (mounted) setState(() => _isProcessing = false);
        await Future.delayed(const Duration(seconds: 1));
        _showOrderConfirmation(context, cart);
        _navigateToReviewIfAny(context);
      }
    } on TimeoutException {
      if (mounted) setState(() => _isProcessing = false);
      _showPaymentError(
        context,
        'Zahtjev je istekao (timeout). Provjeri mrežu/Stripe.',
      );
    } catch (e, st) {
      dev.log('PAYMENT ERROR: $e\n$st', name: 'PAY');
      if (mounted) setState(() => _isProcessing = false);
      _showPaymentError(context, e.toString());
    }
  }

  void _navigateToReviewIfAny(BuildContext context) {
    // reviews može još biti null jer se puni async
    final list = reviews?.items ?? [];
    final existing = list.cast<Review?>().firstWhere(
      (r) => r?.reviewerUserId == AuthProvider.user?.id,
      orElse: () => null,
    );
    const msg = 'Plaćanje uspješno izvršeno!';
    if (existing != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              GuestReviewScreen(existingReview: existing, successMessage: msg),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              GuestReviewScreen(existingReview: existing, successMessage: msg),
        ),
      );
    }
  }

  void _showPaymentSuccess(BuildContext context, CartProvider cart) {
    cart.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Plaćanje uspješno!'),
        content: const Text('Vaša narudžba je uspješno plaćena.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('U redu'),
          ),
        ],
      ),
    );
  }

  void _showOrderConfirmation(BuildContext context, CartProvider cart) {
    cart.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Narudžba potvrđena!'),
        content: const Text('Vaša narudžba je uspješno plaćena.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('U redu'),
          ),
        ],
      ),
    );
  }

  void _showPaymentError(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 48),
        title: const Text('Greška pri plaćanju'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Pokušaj ponovo'),
          ),
        ],
      ),
    );
  }
}
