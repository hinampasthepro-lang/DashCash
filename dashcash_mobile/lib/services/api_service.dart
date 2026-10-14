import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl =
      'http://localhost:5099/api'; // Use http://10.0.2.2:5099/api for Android Emulator, localhost for Chrome/Web[cite: 13]
  final _storage = const FlutterSecureStorage();

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? response.body;
        await _storage.write(key: 'jwt_token', value: token);
        return null; // Null means success (no error)
      } else {
        final errorData = jsonDecode(response.body);
        return errorData['message'] ?? 'Login failed: ${response.body}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  Future<String?> register(
    String email,
    String phoneNumber,
    String password,
    String confirmPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Null means success
      } else {
        final errorData = jsonDecode(response.body);
        return errorData['message'] ?? 'Registration failed: ${response.body}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }
}
