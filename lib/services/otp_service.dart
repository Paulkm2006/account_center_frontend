import 'dart:convert';

import 'package:account_center_frontend/main.dart';
import 'package:account_center_frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class TwoFactorAuthService {

  Future<String> getAuthType(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl/auth/$id'), 
      headers: {
        "Authorization": "Bearer ${AuthService().getJwtCookie()}",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "application/json; charset=UTF-8",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(utf8.decode(response.bodyBytes));
      return jsonMap['type'];
    } else {
      throw Exception('Failed to retrieve auth type');
    }
  }
  Future<String> retrieveTotpCode(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl/auth/$id'), 
      headers: {
        "Authorization": "Bearer ${AuthService().getJwtCookie()}",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "application/json; charset=UTF-8",
      },
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(utf8.decode(response.bodyBytes));
      return jsonMap['data'];  // Changed from 'data' to 'code'
    } else {
      throw Exception('Failed to retrieve OTP');
    }
  }

  Future<Map<String, dynamic>> retrieveSpecialAuthInfo(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl/auth/$id'), 
      headers: {
        "Authorization": "Bearer ${AuthService().getJwtCookie()}",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "application/json; charset=UTF-8",
      },);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(utf8.decode(response.bodyBytes));
      return jsonMap['data'];
    } else {
      throw Exception('Failed to retrieve special auth info');
    }
  }

}