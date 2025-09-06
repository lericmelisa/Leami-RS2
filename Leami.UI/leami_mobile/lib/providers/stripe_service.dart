import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:leami_mobile/providers/auth_provider.dart';

class StripeService {
  static const String _baseUrl = String.fromEnvironment(
    'baseUrl',
    defaultValue: 'http://10.0.2.2:5139',
  );

  static Future<void> init() async {
    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (publishableKey == null || publishableKey.isEmpty) {
      throw Exception('Stripe publishable key not found in .env');
    }

    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  static Future<Map<String, dynamic>?> createPaymentIntent(
    double amount, {
    required String currency,
  }) async {
    try {
      final cents = (amount * 100).round(); // npr. 2.50 -> 250

      final res = await http
          .post(
            Uri.parse('$_baseUrl/Stripe/create-payment-intent'),
            headers: {
              'Content-Type': 'application/json',
              if (AuthProvider.token != null)
                'Authorization': 'Bearer ${AuthProvider.token}',
            },
            body: json.encode({'amount': cents, 'currency': currency}),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      } else {
        debugPrint('PI create failed: ${res.statusCode} ${res.body}');
        return null;
      }
    } on TimeoutException {
      debugPrint('PI create timeout');
      return null;
    } catch (e) {
      debugPrint('Exception creating PI: $e');
      return null;
    }
  }

  static Future<bool> processPayment({
    required double amount,
    required String currency,
  }) async {
    try {
      final data = await createPaymentIntent(amount, currency: currency);
      if (data == null || data['clientSecret'] == null) {
        throw Exception('Failed to create payment intent');
      }
      final clientSecret = data['clientSecret'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Leami Shop',
          style: ThemeMode.dark,
        ),
      );

      // Ovo je FINALNA potvrda u novim verzijama flutter_stripe
      await Stripe.instance.presentPaymentSheet();

      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        debugPrint('User canceled payment sheet.');
        return false;
      }
      throw Exception('Payment failed: ${e.error.localizedMessage}');
    } on TimeoutException {
      throw Exception('Stripe operacija je istekla (timeout).');
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  // (Opciono) Ako koristiš Checkout Session flow negdje:
  static Future<Map<String, dynamic>?> createCheckoutSession({
    required double amount,
    required String productName,
    String currency = 'usd',
  }) async {
    try {
      final amountInCents = (amount * 100).round();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/Stripe/create-checkout-session'),
            headers: {
              'Content-Type': 'application/json',
              if (AuthProvider.token != null)
                'Authorization': 'Bearer ${AuthProvider.token}',
            },
            body: json.encode({
              'amount': amountInCents,
              'productName': productName,
              'currency': currency,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Error creating checkout session: ${response.body}');
        return null;
      }
    } on TimeoutException {
      debugPrint('Checkout session timeout');
      return null;
    } catch (e) {
      debugPrint('Exception creating checkout session: $e');
      return null;
    }
  }
}
