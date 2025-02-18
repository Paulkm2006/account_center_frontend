import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
                    'https://sso.bingyan.net/auth?client_id=e792e867-54d5-4d27-bdf9-9f1d2de43858&scope=openid%20profile%20phone%20email&response_type=code&redirect_uri=http://localhost:8080/callback',
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
