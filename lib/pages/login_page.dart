import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    if (await AuthService().checkJwtCookie()) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please login to continue'),
            ElevatedButton(
                onPressed: () async {
                  final loginUrl = Uri.parse(
                    'https://sso.bingyan.net/auth?client_id=52c60313-2c31-48ba-be94-244976ef2683&scope=openid%20profile%20phone%20email&response_type=code&redirect_uri=https://account-center.bingyan.net/callback',
                  );
                  if (await canLaunchUrl(loginUrl)) {
                    await launchUrl(loginUrl);
                  } else {
                    throw 'Could not launch $loginUrl';
                  }
                },
              child: const Text('Login'),
            ),
          ],
        )
      ),
    );
  }
}
