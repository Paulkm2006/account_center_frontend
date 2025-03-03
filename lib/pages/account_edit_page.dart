import 'package:account_center_frontend/main.dart';
import 'package:account_center_frontend/services/account_service.dart';
import 'package:account_center_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_iconpicker/IconPicker/Packs/MaterialDefault.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:url_launcher/url_launcher_string.dart';

class AccountEditPage extends StatefulWidget {
  final String accountId;

  const AccountEditPage({super.key, required this.accountId});

  @override
  State<AccountEditPage> createState() => _AccountEditPageState();
}

class _AccountEditPageState extends State<AccountEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginUrlController = TextEditingController();
  final _commentController = TextEditingController();
  final _avatarController = TextEditingController();
  bool _isLoading = true;
  bool _isIconMode = false;
  bool _isValidImageUrl = false;
  bool _isTestingImage = false;
  String? _authId;

  @override
  void initState() {
    super.initState();
    if (widget.accountId != "new") {
      _loadAccountData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAccountData() async {

    final data = await AccountService().getAccountDetail(widget.accountId);
    if (data.avatar.startsWith('material:')) {
      setState(() {
        _isIconMode = true;
        _avatarController.text = data.avatar.substring(9);
      });
    }else{
      setState(() {
        _isIconMode = false;
        _avatarController.text = data.avatar.substring(4);
        _testImageUrl(_avatarController.text);
      });
    }

    setState(() {
      _nameController.text = data.name;
      _accountController.text = data.account;
      _passwordController.text = data.password;
      _loginUrlController.text = data.loginUrl ?? '';
      _commentController.text = data.comment ?? '';
      _isLoading = false;
      _authId = data.authId;
    });

  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isIconMode && defaultIcons[_avatarController.text] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid icon name')),
      );
      return;
    }

    if (!_isIconMode && !_isValidImageUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid image URL')),
      );
      return;
    }

    

    final body = jsonEncode({
      'name': _nameController.text,
      'account': _accountController.text,
      'password': _passwordController.text,
      'avatar': _isIconMode? "material:${_avatarController.text}" : "url:${_avatarController.text}",
      'login_url': _loginUrlController.text,
      'comment': _commentController.text,
    });

    http.Response response;

    String id = widget.accountId;

    if (widget.accountId != 'new') {
      response = await http.put(
        Uri.parse('$apiUrl/account/${widget.accountId}'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AuthService().getJwtCookie()}'}, // Add this line
        body: body,
      );
    } else {
      response = await http.post(
        Uri.parse('$apiUrl/account'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AuthService().getJwtCookie()}'}, // Add this line
        body: body,
      );

      id = json.decode(response.body)['id'];
    }

    if (response.statusCode == 200 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully')),
      );
      context.go('/account/$id');
    }
  }

  Future<void> _testImageUrl(String url) async {
    if (url.isEmpty) {
      setState(() {
        _isValidImageUrl = false;
        _isTestingImage = false;
      });
      return;
    }

    setState(() => _isTestingImage = true);

    
    try {
      final response = await http.head(Uri.parse(url));
      final contentType = response.headers['content-type'];
      setState(() {
        _isValidImageUrl = contentType != null && contentType.startsWith('image/');
        _isTestingImage = false;
      });
    } catch (e) {
      setState(() {
        _isValidImageUrl = false;
        _isTestingImage = false;
      });
    }
  }

  Widget _buildAvatarField() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Avatar Type:'),
              const SizedBox(width: 10),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('URL')),
                  ButtonSegment(value: true, label: Text('Icon')),
                ],
                selected: {_isIconMode},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() {
                    _avatarController.clear();
                    _isValidImageUrl = false;
                    _isIconMode = selection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isIconMode)
            ListTile(
              leading: Text(_avatarController.text.isEmpty ? 'Select an icon' : 'Selected:'),
              title: _avatarController.text.isEmpty
                  ? const Icon(Icons.question_mark)
                  : Icon(defaultIcons[_avatarController.text]!.data),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final IconPickerIcon? result = await showIconPicker(context);
                  if (result != null) {
                    setState(() {
                      _avatarController.text = result.name;
                      _isIconMode = true;
                    });
                  }
                },
              ),
            )
          else
            Column(
              children: [
                Row(children: [
                  const Text("You can find most company logos at"),
                  TextButton(
                    onPressed: () => launchUrlString("https://github.com/stratumauth/app/tree/master/icons"),
                    child: const Text('Here'),
                  ),
                  const Text("Make sure to use github raw url."),
                ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _avatarController,
                        decoration: const InputDecoration(
                          labelText: 'Avatar URL',
                        ),
                        onChanged: (value) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (value == _avatarController.text) {
                              if (value.contains('github')) {
                                value = value.replaceAll(
                                    'https://', 'https://gh-proxy.com/');
                              }
                              _avatarController.text = value;
                              _testImageUrl(value);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!_isIconMode && _avatarController.text.isNotEmpty)
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: _isTestingImage
                            ? const CircularProgressIndicator()
                            : _isValidImageUrl
                                ? Image.network(
                                    _avatarController.text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.error);
                                    },
                                  )
                                : const Icon(Icons.broken_image),
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _accountController,
                      decoration: const InputDecoration(labelText: 'Account'),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Account is required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Password is required' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildAvatarField(),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _loginUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Login URL',
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.accountId != 'new') // Only show for existing accounts
                      ElevatedButton.icon(
                        onPressed: () => context.push('/account/${widget.accountId}/auth/$_authId'),
                        icon: const Icon(Icons.security),
                        label: const Text('Manage Authentication'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.go(widget.accountId != 'new' ? '/account/${widget.accountId}' : '/'),
                          label: const Text('Cancel'),
                          icon: const Icon(Icons.cancel),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(Colors.red),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          onPressed: _saveChanges,
                          label: const Text('Save Changes'),
                          icon: const Icon(Icons.save),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    _avatarController.dispose();
    _loginUrlController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
