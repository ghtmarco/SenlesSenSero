import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = "http://localhost:3000/api";
  static String? _currentToken;

  static String? get token => _currentToken;

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$_baseUrl/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.trim(), "password": password.trim()}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentToken = data['token']; // Store token
        return {
          'success': true,
          'message': data['message'],
          'token': data['token'],
          'user': data['user']
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again later.'
      };
    }
  }

  // Dapatkan token saat ini
  static Future<String?> getToken() async {
    return _currentToken;
  }

  // Periksa apakah pengguna adalah admin
  static bool isAdminUser(Map<String, dynamic> userData) {
    return userData['role'] == 'admin';
  }
}
