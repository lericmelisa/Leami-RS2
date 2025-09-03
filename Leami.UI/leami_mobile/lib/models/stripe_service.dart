import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  static const String _baseUrl = 'http://10.0.2.2:5139'; // Vaš backend URL

  static Future<void> init() async {
    Stripe.publishableKey =
        'pk_test_51R1bEA4DwuqFpeUFtLjEMb2snK29VgF3JfaNj2PvjXertPHNNVM3I1i1lxjqvk5c4iopHOAIEiLt0m2pR97i4KoP00zUP0Fg2e';
    await Stripe.instance.applySettings();
  }

  static Future<Map<String, dynamic>?> createPaymentIntent(
    double amount,
  ) async {
    try {
      // Konvertuj amount u cents (pomnožiti sa 100)
      final amountInCents = (amount * 100).round();

      final response = await http.post(
        Uri.parse('$_baseUrl/Stripe/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amountInCents}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error creating payment intent: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception creating payment intent: $e');
      return null;
    }
  }

  static Future<bool> processPayment({
    required double amount,
    required String currency,
  }) async {
    try {
      // 1. Kreiraj Payment Intent na backend-u
      final paymentIntentData = await createPaymentIntent(amount);

      if (paymentIntentData == null) {
        throw Exception('Failed to create payment intent');
      }

      // 2. Inicijalizuj payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['clientSecret'],
          merchantDisplayName: 'Leami Shop',
          style: ThemeMode.dark,
        ),
      );

      // 3. Prikaži payment sheet
      await Stripe.instance.presentPaymentSheet();

      return true;
    } on StripeException catch (e) {
      print('Stripe error: ${e.error.localizedMessage}');
      throw Exception('Payment failed: ${e.error.localizedMessage}');
    } catch (e) {
      print('General error: $e');
      throw Exception('Payment failed: $e');
    }
  }

  static Future<Map<String, dynamic>?> createCheckoutSession({
    required double amount,
    required String productName,
  }) async {
    try {
      final amountInCents = (amount * 100).round();

      final response = await http.post(
        Uri.parse('$_baseUrl/Stripe/create-checkout-session'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': amountInCents,
          'productName': productName,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error creating checkout session: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception creating checkout session: $e');
      return null;
    }
  }
}
