import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:account_center_frontend/services/otp_service.dart';

class SpecialDisplay extends StatefulWidget {
  final String accountId;

  const SpecialDisplay({super.key, required this.accountId});

  @override
  State<SpecialDisplay> createState() => _SpecialDisplayState();
}

class _SpecialDisplayState extends State<SpecialDisplay> {
  Map<String, dynamic>? _authData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSpecialAuthInfo();
  }

  Future<void> _fetchSpecialAuthInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await TwoFactorAuthService().retrieveSpecialAuthInfo(widget.accountId);
      setState(() {
        _authData = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching auth info: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Special Authentication',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoItem('Name', _authData!['name']),
          if (_authData!['email'] != null)
            _buildInfoItem('Email', _authData!['email']),
          if (_authData!['phone'] != null)
            _buildInfoItem('Phone', _authData!['phone']),
          if (_authData!['comment'] != null)
            _buildInfoItem('Comment', _authData!['comment']),
          _buildInfoItem('QQ', _authData!['qq']),
          const Divider(),
        ],
      ),
    );
  }
}
