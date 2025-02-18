import 'package:account_center_frontend/pages/account_detail_page.dart';
import 'package:account_center_frontend/pages/auth_edit_page.dart';
import 'package:account_center_frontend/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:account_center_frontend/providers/theme_provider.dart';
import 'package:account_center_frontend/pages/account_edit_page.dart';

import 'pages/login_page.dart';
import 'pages/callback_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

const apiUrl = 'http://localhost:8080';

void main() {
  usePathUrlStrategy();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainPage()
      ),
      GoRoute(
        path: '/callback',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return CallbackPage(code: code);
        }
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage()
      ),
      GoRoute(
        path: '/account/new',
        builder: (context, state) => const AccountEditPage(
              accountId: 'new',
      )),
      GoRoute(
        path: '/account/:id',
        builder: (context, state) => AccountDetailPage(
          accountId: state.pathParameters['id']!,
        ),
      ),
      // Add this new route
      GoRoute(
        path: '/account/:id/auth/:authId',
        builder: (context, state) => AuthEditPage(
          accountId: state.pathParameters['id']!,
          authId: state.pathParameters['authId'],
        ),
      ),
      GoRoute(
        path: '/account/:id/edit',
        builder: (context, state) => AccountEditPage(
          accountId: state.pathParameters['id']!,
        ),
      ),
      
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          theme: themeProvider.theme,
          routerConfig: _router,
        );
      },
    );
  }
}
