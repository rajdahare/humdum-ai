import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AgeVerificationModal extends StatefulWidget {
  final Function(bool verified) onVerified;

  const AgeVerificationModal({super.key, required this.onVerified});

  @override
  State<AgeVerificationModal> createState() => _AgeVerificationModalState();
}

class _AgeVerificationModalState extends State<AgeVerificationModal> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _error;

  Future<void> _sendOTP() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Call backend to send OTP via Twilio
      await ApiService.post('/auth/send-otp', {
        'phone': _phoneController.text.trim(),
      });
      setState(() {
        _otpSent = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to send OTP: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the OTP');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.post('/auth/verify-otp', {
        'phone': _phoneController.text.trim(),
        'otp': _otpController.text.trim(),
      });

      if (res['verified'] == true) {
        widget.onVerified(true);
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() {
          _error = 'Invalid OTP. Please try again.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Verification failed: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Age Verification Required'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'You must be 18+ to access Night mode. Please verify your age with a phone number.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_otpSent,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+91XXXXXXXXXX',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  hintText: 'Enter 6-digit OTP',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onVerified(false);
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : (_otpSent ? _verifyOTP : _sendOTP),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_otpSent ? 'Verify' : 'Send OTP'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}

