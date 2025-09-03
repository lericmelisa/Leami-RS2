import 'package:flutter/material.dart';
import 'package:leami_mobile/models/order.dart';
import 'package:leami_mobile/models/order_item.dart';
import 'package:leami_mobile/models/review.dart';
import 'package:leami_mobile/models/search_result.dart';
import 'package:leami_mobile/models/stripe_service.dart';
import 'package:leami_mobile/providers/auth_provider.dart';
import 'package:leami_mobile/providers/order_provider.dart';
import 'package:leami_mobile/providers/review_provider.dart';
import 'package:leami_mobile/screens/guest_review_screen.dart';
import 'package:provider/provider.dart';
import 'package:leami_mobile/providers/cart_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'stripe';

  late OrderProvider orderpr;
  late ReviewProvider reviewProvider;
  late OrderRequest orderRequest;

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
                  // Order Summary Card
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

                          // Lista artikala
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

                          // Ukupno
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

                  // Payment Method Selection
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

                          // Stripe Payment Option
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
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
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
                                  Image.asset(
                                    'assets/images/stripe_logo.png', // Dodajte Stripe logo
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.payment,
                                        size: 24,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Cash on Delivery Option (opciono)
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
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping,
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
                                          'Plaćanje pri dostavi',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Platite gotovinom kada stigne dostava',
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

                  // Security Info
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

          // Bottom Payment Button
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
                        : () => _processPayment(context, cart),
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

  Future<void> _processPayment(BuildContext context, CartProvider cart) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      if (_selectedPaymentMethod == 'stripe') {
        // Stripe Payment
        final success = await StripeService.processPayment(
          amount: cart.totalPrice,
          currency: 'usd',
        );

        if (success) {
          final orderRequest = OrderRequest(
            userId: AuthProvider.Id!,
            orderDate: DateTime.now(),
            totalAmount: cart.totalPrice,
            paymentMethod: _selectedPaymentMethod,
            items: cart.itemsList
                .map(
                  (item) => OrderItemRequest(
                    articleId: item.id,
                    quantity: item.quantity,
                    unitPrice: item.price,
                  ),
                )
                .toList(),
          );
          await orderpr.insert(orderRequest);
          _showPaymentSuccess(context, cart);
          if (mounted) {
            try {
              final existingReview = reviews!.items!.firstWhere(
                (review) => review.reviewerUserId == 3,
              );

              // If a review is found, navigate to the review screen for editing
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GuestReviewScreen(existingReview: existingReview),
                ),
              );
            } catch (e) {
              // If no review is found, navigate to the review screen to create a new review
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const GuestReviewScreen(),
                ),
              );
            }
          }
        }
      } else if (_selectedPaymentMethod == 'cod') {
        // Cash on Delivery - samo potvrdi narudžbu
        final orderRequest = OrderRequest(
          userId: 3,
          // AuthProvider.Id!,
          orderDate: DateTime.now(),
          totalAmount: cart.totalPrice,
          paymentMethod: _selectedPaymentMethod,
          items: cart.itemsList
              .map(
                (item) => OrderItemRequest(
                  articleId: item.id,
                  quantity: item.quantity,
                  unitPrice: item.price,
                ),
              )
              .toList(),
        );
        await orderpr.insert(orderRequest);
        await Future.delayed(
          const Duration(seconds: 2),
        ); // Simulacija API poziva
        _showOrderConfirmation(context, cart);
        if (mounted) {
          try {
            final existingReview = reviews!.items!.firstWhere(
              (review) => review.reviewerUserId == 3,
            );

            // If a review is found, navigate to the review screen for editing
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GuestReviewScreen(existingReview: existingReview),
              ),
            );
          } catch (e) {
            // If no review is found, navigate to the review screen to create a new review
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const GuestReviewScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      _showPaymentError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showPaymentSuccess(BuildContext context, CartProvider cart) {
    cart.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Plaćanje uspješno!'),
          content: const Text('Vaša narudžba je uspješno plaćena.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('U redu'),
            ),
          ],
        );
      },
    );
  }

  void _showOrderConfirmation(BuildContext context, CartProvider cart) {
    cart.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Narudžba potvrđena!'),
          content: const Text('Vaša narudžba je uspješno plaćena.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('U redu'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentError(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.error, color: Colors.red, size: 48),
          title: const Text('Greška pri plaćanju'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        );
      },
    );
  }
}
