import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/voice_service.dart';

class MicButton extends StatefulWidget {
  final void Function(String text) onResult;
  final bool isProcessing;
  final VoidCallback? onStop;
  const MicButton({
    super.key,
    required this.onResult,
    this.isProcessing = false,
    this.onStop,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  final VoiceService _voice = VoiceService();
  bool _listening = false;

  Future<void> _record() async {
    if (_listening) return; // Prevent double-tap
    
    setState(() => _listening = true);
    
    try {
      final result = await _voice.recordOnce(listenMs: 6000);
      if (!mounted) return;
      
      final text = result ?? '';
      if (text.isNotEmpty) {
        widget.onResult(text);
      }
    } catch (e) {
      debugPrint('Mic button error: $e');
      // Show error to user if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _listening = false);
      }
    }
  }

  @override
  void dispose() {
    // Clean up if still listening
    if (_listening) {
      _voice.stopRecording();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    // Show stop button when processing
    if (widget.isProcessing) {
      return GestureDetector(
        onTap: widget.onStop,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.errorContainer,
            boxShadow: [
              BoxShadow(
                color: scheme.error.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(
            Icons.stop_circle,
            color: scheme.onErrorContainer,
          ),
        ),
      );
    }
    
    // Show mic button when not processing
    return GestureDetector(
      onTap: _listening ? null : _record,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _listening ? scheme.errorContainer : scheme.primary,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Icon(
          _listening ? Icons.mic : Icons.mic_none,
          color: _listening ? scheme.onErrorContainer : scheme.onPrimary,
        ),
      ),
    );
  }
}


