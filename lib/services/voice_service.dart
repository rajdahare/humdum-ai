import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isSpeaking = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      final available = await _speech.initialize();
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(1.0);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _isInitialized = available;
      return available;
    } catch (e) {
      debugPrint('VoiceService initialization error: $e');
      return false;
    }
  }

  Future<bool> hasSpeech() async {
    if (!_isInitialized) await initialize();
    return _speech.hasPermission;
  }

  Future<String?> recordOnce({int listenMs = 6000}) async {
    // Stop any ongoing TTS before starting recording
    if (_isSpeaking) {
      await stopSpeaking();
      await Future.delayed(const Duration(milliseconds: 300)); // Brief pause
    }

    // Don't start if already recording
    if (_isRecording) {
      await stopRecording();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!_isInitialized) {
      if (!await initialize()) return null;
    }

    _isRecording = true;
    String captured = '';
    bool isFinal = false;

    try {
      await _speech.listen(
        onResult: (result) {
          captured = result.recognizedWords;
          isFinal = result.finalResult;
        },
        listenFor: Duration(milliseconds: listenMs),
        pauseFor: const Duration(seconds: 3),
      );

      // Wait for recording to complete or timeout
      await Future.delayed(Duration(milliseconds: listenMs + 500));

      // Stop if still listening
      if (await _speech.isListening) {
        await _speech.stop();
      }

      // Wait a bit more for final results
      if (!isFinal) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Speech recognition error: $e');
      try {
        if (await _speech.isListening) {
          await _speech.stop();
        }
      } catch (_) {}
      _isRecording = false;
      return null;
    } finally {
      _isRecording = false;
      try {
        if (await _speech.isListening) {
          await _speech.stop();
        }
      } catch (_) {}
    }

    return captured.trim().isEmpty ? null : captured.trim();
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    try {
      if (await _speech.isListening) {
        await _speech.stop();
      }
      _isRecording = false;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
    }
  }

  /// Cleans markdown and formatting from text to make it natural for speech
  String _cleanForSpeech(String text) {
    String cleaned = text;
    
    // First, handle bullet points and lists - remove markers at start of lines
    // This must be done line-by-line to catch standalone asterisks
    final lines = cleaned.split('\n');
    final cleanedLines = <String>[];
    for (var line in lines) {
      var processedLine = line.trim();
      
      // Remove bullet point markers: *, -, •, or numbered lists (1., 2., etc.)
      // Match: "*   text" or "- text" or "• text" or "1. text"
      processedLine = processedLine.replaceAll(RegExp(r'^[\*\-•]\s+'), '');
      processedLine = processedLine.replaceAll(RegExp(r'^\d+\.\s+'), '');
      
      // Remove any standalone asterisks that might be at the start
      if (processedLine.startsWith('*') && processedLine.length > 1) {
        processedLine = processedLine.substring(1).trim();
      }
      
      if (processedLine.isNotEmpty) {
        cleanedLines.add(processedLine);
      }
    }
    cleaned = cleanedLines.join('. '); // Join list items with periods
    
    // Remove markdown bold (**text** or __text__) - keep the text, remove markers
    cleaned = cleaned.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (match) => match.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'__(.+?)__'), (match) => match.group(1) ?? '');
    
    // Remove markdown italic (*text* or _text_) - keep the text, remove markers
    // Be careful not to match standalone asterisks that are part of words
    cleaned = cleaned.replaceAllMapped(RegExp(r'(?<!\*)\*([^*\n\s]+[^*\n]*[^*\n\s]+)\*(?!\*)'), (match) => match.group(1) ?? '');
    
    // Remove any remaining standalone asterisks (safety check)
    cleaned = cleaned.replaceAll(RegExp(r'\s*\*\s*'), ' ');
    
    // Remove code blocks (`code`) - keep the text, remove markers
    cleaned = cleaned.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1) ?? '');
    
    // Replace common punctuation that sounds weird when spoken
    cleaned = cleaned.replaceAll('...', '.'); // Ellipsis to period
    cleaned = cleaned.replaceAll('---', '—'); // Em dash
    cleaned = cleaned.replaceAll('--', '—'); // En dash
    
    // Remove URLs (they don't read well)
    cleaned = cleaned.replaceAll(RegExp(r'https?://[^\s]+'), '[link]');
    
    // Replace multiple spaces with single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove multiple newlines - convert to single space or period
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '. ');
    cleaned = cleaned.replaceAll(RegExp(r'\n{2}'), '. ');
    cleaned = cleaned.replaceAll(RegExp(r'\n'), ' ');
    
    // Remove leading/trailing spaces
    cleaned = cleaned.trim();
    
    // Ensure text ends with proper punctuation if it's a sentence
    if (cleaned.isNotEmpty && 
        !cleaned.endsWith('.') && 
        !cleaned.endsWith('!') && 
        !cleaned.endsWith('?') &&
        !cleaned.endsWith(':') &&
        !cleaned.endsWith('।')) { // Hindi full stop
      // Only add period if it looks like a sentence (has some length)
      if (cleaned.length > 10) {
        cleaned += '.';
      }
    }
    
    // Final cleanup - remove any double periods or spaces
    cleaned = cleaned.replaceAll(RegExp(r'\.{2,}'), '.');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.trim();
    
    return cleaned;
  }
  
  /// Detects if text contains Hindi/Devanagari characters
  bool _isHindi(String text) {
    return RegExp(r'[\u0900-\u097F]').hasMatch(text);
  }

  Future<void> speak(String text) async {
    // Stop any ongoing recording before speaking
    if (_isRecording) {
      await stopRecording();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    try {
      await _tts.stop();
      _isSpeaking = false;
      
      if (text.isNotEmpty) {
        final cleanedText = _cleanForSpeech(text);
        if (cleanedText.isNotEmpty) {
          _isSpeaking = true;
          
          // Set language based on content
          try {
            if (_isHindi(cleanedText)) {
              await _tts.setLanguage('hi-IN'); // Hindi
            } else {
              await _tts.setLanguage('en-US'); // English
            }
          } catch (e) {
            // If language not supported, use default
            await _tts.setLanguage('en-US');
          }
          
          // Set up completion handler
          _tts.setCompletionHandler(() {
            _isSpeaking = false;
          });
          
          // Set up start handler
          _tts.setStartHandler(() {
            _isSpeaking = true;
          });
          
          await _tts.speak(cleanedText);
        }
      }
    } catch (e) {
      debugPrint('TTS error: $e');
      _isSpeaking = false;
    }
  }
  
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
      _isSpeaking = false;
    }
  }

  bool get isRecording => _isRecording;
  bool get isSpeaking => _isSpeaking;
}


