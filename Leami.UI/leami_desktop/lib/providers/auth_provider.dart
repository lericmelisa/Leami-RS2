import "package:http/http.dart" as http;
import 'dart:convert';

class AuthProvider {
  static String? email;
  static String? password;

  static String? token;

  static Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse('http://localhost:5139/User/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Email': email, 'Password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        token = responseData['token']; // spremi token koji dobiješ od API-ja
        return true;
      }
      return false;
    } catch (error) {
      print(error);
      return false;
    }
  }

  static void logout() {
    token = null;
  }

  // Helper metoda za provjeru je li korisnik logiran
  static bool get isAuthenticated => token != null;
}
