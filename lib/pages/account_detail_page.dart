import 'package:account_center_frontend/models/user.dart';
import 'package:account_center_frontend/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:account_center_frontend/models/account.dart';
import 'package:account_center_frontend/services/account_service.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:account_center_frontend/widgets/totp_display.dart';
import 'package:account_center_frontend/widgets/special_display.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AccountDetailPage extends StatelessWidget {
  final String accountId;

  const AccountDetailPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/');
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
      body: FutureBuilder<Account>(
        future: AccountService().getAccountDetail(accountId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final account = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      // Wide layout - horizontal
                      return Row(
                        children: [
                          _buildAccountBasicInfo(account),
                          const SizedBox(width: 32),
                          _buildUserAndActionPanel(account, context),
                        ],
                      );
                    } else {
                      // Narrow layout - vertical
                      return Column(
                        children: [
                          _buildAccountBasicInfo(account),
                          const SizedBox(height: 16),
                          _buildUserAndActionPanel(account, context),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _buildDetailItem('Account', account.account, true, false, context),
                    _buildDetailItem('Password', account.password, true, false, context),
                    if (account.authType != null) ...[
                      if (account.authType == "totp") Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TotpDisplay(accountId: account.authId!),
                      ),
                      if (account.authType == "email" || account.authType == "phone")
                            Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SpecialDisplay(accountId: account.authId!),
                      ),
                    ],
                    if (account.loginUrl != null)
                      _buildDetailItem('Login URL', account.loginUrl!, false, true, context),
                    if (account.comment != null)
                      _buildDetailItem('Comment', account.comment!, false, false, context),
                    _buildDetailItem('Created At', 
                      DateTime.fromMillisecondsSinceEpoch(account.createdAt)
                      .toLocal().toString(), false, false,
                            context),
                    _buildDetailItem('Updated At', 
                      DateTime.fromMillisecondsSinceEpoch(account.updatedAt)
                      .toLocal().toString(),
                            false, false,
                            context),
                    ],
                  ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAccountBasicInfo(Account account) {
    return Row(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: account.getAvatar(),
        ),
        const SizedBox(width: 32),
        Text(
          account.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUserAndActionPanel(Account account, BuildContext context) {
    return Wrap(
      spacing: 32,
      runSpacing: 16,
      alignment: WrapAlignment.start,
      children: [
        _buildUserItem("Creator", account.creator, context),
        _buildUserItem("Updater", account.updator, context),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Actions", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/account/${account.id}/edit');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.red),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Account'),
                            content: const Text('Are you sure you want to delete this account?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await AccountService().deleteAccount(account.id);
                                  if (context.mounted) {
                                    context.go('/');
                                  }
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, bool copyable, bool link, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: link
                  ? InkWell(
                    onTap: () => launchUrlString(value),
                    child: Text(
                      value,
                      style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      ),
                    ),
                    )
                  : Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                ),
              ),
              if (copyable)
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    Clipboard.setData(ClipboardData(text: value));
                  },
                ),
              if (link)
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening link'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    launchUrlString(value);
                  },
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildUserItem(String label, User user, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _showUserDetail(context, label, user),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  SizedBox(height: 32, child: user.avatar),
                  const SizedBox(width: 8),
                  Text(
                    user.nickname,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showUserDetail(BuildContext context, String label, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogItem('Name', user.nickname),
            _buildDialogItem('Email', user.email),
            _buildDialogItem('Phone', user.phone),
            _buildDialogItem('Role', user.role),
            _buildDialogItem('Group', user.group),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
          const Divider(),
        ],
      ),
    );
  }

  

}
