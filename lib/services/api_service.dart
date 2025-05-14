import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.104:5118/api';

  Future<Map<String, dynamic>> login(String userName, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Account/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userName': userName, 'password': password}),
    );
    print('Login response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['token']);
      _logToken(data['token']);
      return data;
    }
    throw Exception(response.body.isNotEmpty
        ? jsonDecode(response.body)['message'] ??
        'Login failed: ${response.statusCode} - ${response.body}'
        : 'Login failed: ${response.statusCode} - No response body');
  }

  Future<Map<String, dynamic>> register(
      String userName, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Account/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userName': userName, 'email': email, 'password': password}),
    );
    print('Register response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['token']);
      _logToken(data['token']);
      return data;
    }
    throw Exception(response.body.isNotEmpty
        ? jsonDecode(response.body)['message'] ??
        'Registration failed: ${response.statusCode} - ${response.body}'
        : 'Registration failed: ${response.statusCode} - No response body');
  }

  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found. Please log in again.');

    print('Using JWT token for profile: $token');
    _logToken(token);

    final response = await http.get(
      Uri.parse('$baseUrl/Profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Future<List<Map<String, dynamic>>> getFeedbacks() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/Feedback'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('GET /api/Feedback response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load feedbacks: ${response.statusCode}');
      }
    }




    print('GET /api/Profile response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) throw Exception('Empty response from server');
      return jsonDecode(response.body);
    }
    throw Exception(response.body.isNotEmpty
        ? jsonDecode(response.body)['message'] ??
        'Failed to fetch profile: ${response.statusCode} - ${response.body}'
        : 'Failed to fetch profile: ${response.statusCode} - No response body');
  }

  Future<Map<String, dynamic>> createProfile(
      String firstName, String lastName, String dateOfBirth) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found. Please log in again.');

    print('Using JWT token for profile: $token');

    final response = await http.post(
      Uri.parse('$baseUrl/Profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
      }),
    );

    print('POST /api/Profile response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) throw Exception('Empty response from server');
      return jsonDecode(response.body);
    }
    throw Exception(response.body.isNotEmpty
        ? jsonDecode(response.body)['message'] ??
        'Failed to update profile: ${response.statusCode} - ${response.body}'
        : 'Failed to update profile: ${response.statusCode} - No response body');
  }

  void _logToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid JWT format');
        return;
      }
      final payload =
      jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      print('JWT payload: $payload');
      print('UserId from JWT: ${payload['sub']}');
    } catch (e) {
      print('Error decoding JWT: $e');
    }
  }


  Future<List<Map<String, dynamic>>> getFeedbacks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/Feedback'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('GET /api/Feedback response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load feedbacks: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createFeedback(String message, int rating) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/Feedback'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'rating': rating,
      }),
    );

    print('POST /api/Feedback response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create feedback: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateFeedback(int id, String message, int rating) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.put(
      Uri.parse('$baseUrl/Feedback/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'rating': rating,
      }),
    );

    print('PUT /api/Feedback/$id response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update feedback: ${response.statusCode}');
    }
  }

  Future<void> deleteFeedback(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.delete(
      Uri.parse('$baseUrl/Feedback/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('DELETE /api/Feedback/$id response: ${response.statusCode}');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete feedback: ${response.statusCode}');
    }
  }



  Future<List<Map<String, dynamic>>> getAccessLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/AccessLog'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('GET /api/AccessLog response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load access logs: ${response.statusCode}');
    }
  }




}