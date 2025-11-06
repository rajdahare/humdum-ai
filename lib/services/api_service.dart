import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Replace <PROJECT_ID> after user provides Firebase file
  static String projectId = 'pa-app-fa5b7';
  static String get baseUrl {
    // Use local emulator in debug/web to test quickly
    if (kDebugMode) {
      return 'http://127.0.0.1:5002/$projectId/us-central1/api';
    }
    return 'https://us-central1-$projectId.cloudfunctions.net/api';
  }
}

class ApiService {
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final user = FirebaseAuth.instance.currentUser;
    final isDemo = kDebugMode && user == null; // Only demo if not logged in
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: {
        if (isDemo) 'demo': 'true',
      },
    );
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (!isDemo && token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (isDemo) 'x-demo': 'true',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('API error ${res.statusCode}: ${res.body}');
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final user = FirebaseAuth.instance.currentUser;
    final isDemo = kDebugMode && user == null; // Only demo if not logged in
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: {
        if (isDemo) 'demo': 'true',
      },
    );
    final res = await http.get(
      uri,
      headers: {
        if (!isDemo && token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (isDemo) 'x-demo': 'true',
      },
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('API error ${res.statusCode}: ${res.body}');
  }
}


