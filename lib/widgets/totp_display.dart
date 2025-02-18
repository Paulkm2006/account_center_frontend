import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:account_center_frontend/services/otp_service.dart';

class TotpDisplay extends StatefulWidget {
  final String accountId;

  const TotpDisplay({super.key, required this.accountId});

  @override
  State<TotpDisplay> createState() => _TotpDisplayState();
}

class _TotpDisplayState extends State<TotpDisplay> {
  String? _totpCode;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  bool _isLoading = false;
  int _remainingSeconds = 30;

  @override
  void initState() {
    super.initState();
    _fetchTotpCode();
    // Refresh TOTP every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchTotpCode();
      _remainingSeconds = 30;
    });
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingSeconds = _remainingSeconds > 0 ? _remainingSeconds - 1 : 30;
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTotpCode() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final code = await TwoFactorAuthService().retrieveTotpCode(widget.accountId);
      setState(() {
        _totpCode = code;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching TOTP code: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Text(
                'TOTP Code',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '$_remainingSeconds s',
                style: TextStyle(
                  color: _remainingSeconds <= 5 ? Colors.red : null,
                  fontWeight: _remainingSeconds <= 5 ? FontWeight.bold : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _fetchTotpCode,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  _totpCode ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Monospace',
                    letterSpacing: 2,
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _totpCode == null
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: _totpCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('TOTP code copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
