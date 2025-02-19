import 'package:flutter/material.dart';
import 'package:account_center_frontend/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:account_center_frontend/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthEditPage extends StatefulWidget {
  final String accountId;
  final String? authId;

  const AuthEditPage({super.key, required this.accountId, this.authId});

  @override
  State<AuthEditPage> createState() => _AuthEditPageState();
}

class _AuthEditPageState extends State<AuthEditPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedAuthType = 'none';
  String _selectedTotpAlgorithm = 'SHA1';
  final _totpKeyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  final _qqController = TextEditingController();
  bool _isLoading = true;
  bool _hasExistingAuth = false;

  final List<String> _authTypes = ['none','totp', 'email', 'phone'];
  final List<String> _totpAlgorithms = ['SHA1', 'SHA256', 'SHA512'];

  @override
  void initState() {
    super.initState();
    if (widget.authId != null) {
      _checkExistingAuth();
    } else {
      setState(() {
      _isLoading = false;
      _selectedAuthType = 'none';});
    }
  }

  Future<void> _checkExistingAuth() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/auth/${widget.authId}'),
        headers: {
          'Authorization': 'Bearer ${AuthService().getJwtCookie()}'
        },
      );
      
      if (response.statusCode == 200) {
        final j = jsonDecode(response.body);
        setState(() {
          _selectedAuthType = j['type'];
          final data = j['data'];
          if (_selectedAuthType == 'email') {
            _hasExistingAuth = true;
            _emailController.text = data['email'];
            _nameController.text = data['name'];
            _commentController.text = data['comment'];
            _qqController.text = data['qq'];
          } else if (_selectedAuthType == 'phone') {
            _hasExistingAuth = true;
            _nameController.text = data['name'];
            _commentController.text = data['comment'];
            _qqController.text = data['qq'];
            _phoneController.text = data['phone'] ?? '';
          }
        });
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExistingAuth() async {
    try {
      await http.delete(
        Uri.parse('$apiUrl/auth/${widget.authId}'),
        headers: {
          'Authorization': 'Bearer ${AuthService().getJwtCookie()}'
        },
      );
      await http.post(
        Uri.parse('$apiUrl/account/${widget.accountId}/auth'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService().getJwtCookie()}'
        },
        body: jsonEncode({'auth_id': null}),
      );
      setState(() => _hasExistingAuth = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete existing auth')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Existing Auth'),
          content: const Text(
            'The existing authentication must be deleted before adding a new one. Continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteExistingAuth();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAuth() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAuthType == 'none') context.go('/account/${widget.accountId}');

    final Map<String, dynamic> authData = {
      'type': _selectedAuthType,
    };

    if (_selectedAuthType == 'totp') {
      authData['algorithm'] = _selectedTotpAlgorithm;
      authData['key'] = _totpKeyController.text;
      authData['digits'] = 6;
    } else if (_selectedAuthType == 'email') {
      authData['email'] = _emailController.text;
      authData['name'] = _nameController.text;
      authData['comment'] = _commentController.text;
      authData['qq'] = _qqController.text;
    } else if (_selectedAuthType == 'phone') {
      authData['phone'] = _phoneController.text;
      authData['name'] = _nameController.text;
      authData['comment'] = _commentController.text;
      authData['qq'] = _qqController.text;
    }

    try {
      final responseAuth = await http.post(
        Uri.parse('$apiUrl/auth/$_selectedAuthType'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService().getJwtCookie()}'
        },
        body: jsonEncode(authData),
      );

      final aId = jsonDecode(responseAuth.body)['id'];

      final responseAccount = await http.post(
        Uri.parse('$apiUrl/account/${widget.accountId}/auth'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService().getJwtCookie()}'
        },
        body: jsonEncode({'auth_id': aId}),
      );

      if (responseAccount.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auth saved successfully')),
        );
        context.go('/account/${widget.accountId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save auth')),
        );
      }
    }
  }

  Widget _buildAuthForm() {
    switch (_selectedAuthType) {
      case 'totp':
        return Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedTotpAlgorithm,
              decoration: const InputDecoration(labelText: 'TOTP Algorithm'),
              items: _totpAlgorithms.map((algorithm) {
                return DropdownMenuItem(
                  value: algorithm,
                  child: Text(algorithm.toUpperCase()),
                );
              }).toList(),
              onChanged: _hasExistingAuth ? null : (value) {
                setState(() => _selectedTotpAlgorithm = value!);
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _totpKeyController,
              decoration: const InputDecoration(
                labelText: 'TOTP Key',
                hintText: 'Enter your TOTP secret key',
              ),
              enabled: !_hasExistingAuth,
              validator: (value) => 
                  value?.isEmpty == true ? 'TOTP key is required' : null,
            ),
          ],
        );
      case 'email':
        return Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
              ),
              enabled: !_hasExistingAuth,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Email is required';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
              enabled: !_hasExistingAuth,
              validator: (value) => 
                  value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
              ),
              enabled: !_hasExistingAuth,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _qqController,
              decoration: const InputDecoration(
                labelText: 'QQ',
              ),
              enabled: !_hasExistingAuth,
            ),
            const SizedBox(height: 20),
          ],
        );
      case 'phone':
        return Column(
          children: [
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
              ),
              enabled: !_hasExistingAuth,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Phone number is required';
                if (!RegExp(r'^\d{10,11}$').hasMatch(value!)) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
              enabled: !_hasExistingAuth,
              validator: (value) => 
                  value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
              ),
              enabled: !_hasExistingAuth,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _qqController,
              decoration: const InputDecoration(
                labelText: 'QQ',
              ),
              enabled: !_hasExistingAuth,
            ),
            const SizedBox(height: 20),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Authentication'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_hasExistingAuth)
                Card(
                  color: Colors.amber[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Existing authentication found',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _showDeleteConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete Existing Auth'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedAuthType,
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: _authTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: _hasExistingAuth ? null : (value) {
                  setState(() => _selectedAuthType = value!);
                },
              ),
              const SizedBox(height: 20),
              _buildAuthForm(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/account/${widget.accountId}'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _hasExistingAuth ? null : _saveAuth,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Auth'),
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
    _totpKeyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
