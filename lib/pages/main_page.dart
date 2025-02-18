import 'package:account_center_frontend/services/auth_service.dart';
import 'package:account_center_frontend/services/account_service.dart';
import 'package:account_center_frontend/models/account.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' show Provider, ReadContext;
import 'package:account_center_frontend/providers/theme_provider.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().checkJwtCookie(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Account Center'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  context.push('/account/new');
                },
              ),
              IconButton(
                icon: Icon(
                  Provider.of<ThemeProvider>(context, listen: true).isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () {
                  context.read<ThemeProvider>().toggleTheme();
                },
              ),
              
            ],
          ),
          body: FutureBuilder<List<ListAccount>>(
            future: AccountService().getAccounts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final accounts = snapshot.data ?? [];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  // More responsive grid calculation
                  final crossAxisCount = (width / 180).floor().clamp(1, 6);
                  final itemWidth = (width - (16 * (crossAxisCount + 1))) / crossAxisCount;
                  final avatarSize = (itemWidth * 0.3).clamp(32.0, 64.0);
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return Card(
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            context.push('/account/${account.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: avatarSize,
                                  width: avatarSize,
                                  child: account.getAvatar()
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  account.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: (itemWidth * 0.1).clamp(12.0, 20.0),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateTime.fromMillisecondsSinceEpoch(account.updatedAt)
                                      .toUtc()
                                      .add(const Duration(hours: 8))
                                      .toString(),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: (itemWidth * 0.07).clamp(10.0, 14.0),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
