import 'package:account_center_frontend/services/auth_service.dart';
import 'package:account_center_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CallbackPage extends StatefulWidget {
  final String? code;
  
  const CallbackPage({super.key, this.code});

  @override
  State<CallbackPage> createState() => _CallbackPageState();
}

class _CallbackPageState extends State<CallbackPage> {
  Future<void> exchangeCodeForToken(String code) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/callback?code=$code'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timed out'),
      );


      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];
        final expirationDate = DateTime.now().add(
          const Duration(days: 7),
        );
        AuthService().setJwtCookie(token, expirationDate);
        if (mounted) {
          context.go('/');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to exchange code: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to exchange code: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.code != null) {
      exchangeCodeForToken(widget.code!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
