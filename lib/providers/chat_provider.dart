import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import '../services/voice_service.dart';

enum ChatMode { night, funLearn, health, finance }

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = LocalStorage.loadMessages();
  List<Map<String, String>> _conversationHistory = [];
  final VoiceService _voiceService = VoiceService();
  ChatMode _mode = ChatMode.funLearn;
  bool _isProcessing = false;
  bool _shouldStop = false;
  bool _isStopped = false; // Track if stopped mid-response
  bool _isVoiceResponseEnabled = true;

  ChatProvider() {
    _initConversationHistory();
  }

  void _initConversationHistory() {
    // Load history and ensure it's not too large
    _conversationHistory = LocalStorage.loadConversationHistory();
    
    // Extra safety: trim on init if somehow still too large
    if (_conversationHistory.length > 20) {
      debugPrint('ChatProvider init: Trimming history from ${_conversationHistory.length} to 20');
      _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 20);
      LocalStorage.saveConversationHistory(_conversationHistory);
    }
    
    debugPrint('ChatProvider initialized with ${_conversationHistory.length} history messages');
  }

  List<Message> get messages => List.unmodifiable(_messages);
  List<Map<String, String>> get conversationHistory => List.unmodifiable(_conversationHistory);
  ChatMode get mode => _mode;
  bool get isProcessing => _isProcessing;
  bool get isStopped => _isStopped;
  bool get isVoiceResponseEnabled => _isVoiceResponseEnabled;
  bool get isSpeaking => _voiceService.isSpeaking;
  
  void toggleVoiceResponse() {
    _isVoiceResponseEnabled = !_isVoiceResponseEnabled;
    if (!_isVoiceResponseEnabled) {
      _voiceService.stopSpeaking();
    }
    notifyListeners();
  }
  
  Future<void> stopVoice() async {
    await _voiceService.stopSpeaking();
    notifyListeners();
    // Notify again after a brief delay to ensure UI updates
    Future.delayed(const Duration(milliseconds: 100), () {
      notifyListeners();
    });
  }

  void setMode(ChatMode mode) {
    _mode = mode;
    notifyListeners();
  }
  
  bool get isNightMode => _mode == ChatMode.night;

  void stopProcessing() {
    if (!_isProcessing) return; // Already stopped
    
    _shouldStop = true;
    _isStopped = true;
    _isProcessing = false;
    
    // Immediately stop TTS and recording
    _voiceService.stopSpeaking();
    _voiceService.stopRecording();
    
    notifyListeners();
    
    // Reset stopped flag after a short delay so UI can show feedback
    Future.delayed(const Duration(milliseconds: 500), () {
      _isStopped = false;
      notifyListeners();
    });
  }

  void clearMessages() {
    _messages.clear();
    LocalStorage.saveMessages(_messages);
    notifyListeners();
  }

  Future<void> startNewConversation() async {
    debugPrint('Starting new conversation...');
    
    // Clear conversation history for AI context
    _conversationHistory.clear();
    await LocalStorage.clearConversationHistory();
    
    // Clear visible messages too (fresh start like ChatGPT)
    _messages.clear();
    await LocalStorage.saveMessages(_messages);
    
    // Reset any processing state
    _isProcessing = false;
    _shouldStop = false;
    _isStopped = false;
    
    // Stop any ongoing voice
    await _voiceService.stopSpeaking();
    await _voiceService.stopRecording();
    
    debugPrint('New conversation started successfully');
    notifyListeners();
  }

  Future<void> addUserMessage(String text, {String? tierLevel}) async {
    // If already processing, stop current and process new immediately
    if (_isProcessing) {
      stopProcessing();
      // Wait a bit for cleanup but not too long
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    // Reset stop flag for new message
    _shouldStop = false;
    _isStopped = false;
    
    final msg = Message(
      id: const Uuid().v4(),
      text: text,
      createdAt: DateTime.now(),
      sender: Sender.user,
    );
    _messages.insert(0, msg);
    await LocalStorage.saveMessages(_messages);
    notifyListeners();
    
    // Process new message with tier information
    await _processWithBackend(text, tierLevel: tierLevel);
  }

  Future<void> _processWithBackend(String text, {String? tierLevel}) async {
    _isProcessing = true;
    _shouldStop = false;
    notifyListeners();

    try {
      // Add user message to conversation history
      _conversationHistory.add({'role': 'user', 'content': text});
      
      // Limit conversation history to last 20 messages to prevent stack overflow
      if (_conversationHistory.length > 20) {
        debugPrint('Trimming conversation history from ${_conversationHistory.length} to 20');
        // Keep only the last 20 items
        final itemsToKeep = _conversationHistory.sublist(_conversationHistory.length - 20);
        _conversationHistory.clear();
        _conversationHistory.addAll(itemsToKeep);
        await LocalStorage.saveConversationHistory(_conversationHistory);
      }
      
      final resp = await ApiService.post('/ai/process', {
        'message': text,
        'mode': _mode.name,
        'conversationHistory': _conversationHistory,
        'tierLevel': tierLevel ?? 'tier1', // Send tier to backend
      });

      if (_shouldStop) {
        _isProcessing = false;
        notifyListeners();
        return;
      }

      final reply = (resp['response'] ?? '').toString();
      if (reply.isEmpty) {
        if (_shouldStop) {
          _isProcessing = false;
          notifyListeners();
          return;
        }
        // Show error message if no response
        final errorMsg = Message(
          id: const Uuid().v4(),
          text: 'Sorry, I did not receive a response. Please try again.',
          createdAt: DateTime.now(),
          sender: Sender.ai,
        );
        _messages.insert(0, errorMsg);
        await LocalStorage.saveMessages(_messages);
        _isProcessing = false;
        notifyListeners();
        return;
      }

      if (_shouldStop) {
        _isProcessing = false;
        notifyListeners();
        return;
      }

      // Don't add message if stopped
      if (_shouldStop) {
        _isProcessing = false;
        notifyListeners();
        return;
      }

      final aiMsg = Message(
        id: const Uuid().v4(),
        text: reply,
        createdAt: DateTime.now(),
        sender: Sender.ai,
      );
      _messages.insert(0, aiMsg);
      await LocalStorage.saveMessages(_messages);
      
      // Add AI response to conversation history
      _conversationHistory.add({'role': 'assistant', 'content': reply});
      await LocalStorage.saveConversationHistory(_conversationHistory);
      
      _isProcessing = false;
      notifyListeners();

      // Only speak if not stopped and voice is enabled
      if (!_shouldStop && _isVoiceResponseEnabled) {
        await _voiceService.speak(reply);
        notifyListeners(); // Update UI when voice starts
        
        // Check again after speaking starts in case user stopped during TTS
        if (_shouldStop) {
          await _voiceService.stopSpeaking();
          notifyListeners(); // Update UI when voice stops
        }
        
        // Wait a bit then notify to update speaking state
        Future.delayed(const Duration(milliseconds: 500), () {
          notifyListeners();
        });
      }
    } catch (e) {
      if (_shouldStop) {
        _isProcessing = false;
        notifyListeners();
        return;
      }
      
      // Parse user-friendly error message
      String errorMessage = 'Sorry, something went wrong. Please try again.';
      
      final errorStr = e.toString();
      debugPrint('Chat API error: $errorStr');
      
      // Extract error message from API response
      if (errorStr.contains('API error 500:')) {
        // Try to extract clean error message
        if (errorStr.contains('The conversation has become too long')) {
          errorMessage = '💬 The conversation is too long. Please start a new conversation to continue.';
        } else if (errorStr.contains('Maximum call stack size exceeded')) {
          errorMessage = '💬 The conversation history is full. Please start a new conversation.';
        } else if (errorStr.contains('Unable to connect')) {
          errorMessage = '📡 Unable to connect to AI service. Please check your internet connection.';
        } else if (errorStr.contains('timeout')) {
          errorMessage = '⏱️ Request timed out. Please try again.';
        } else if (errorStr.contains('rate limited') || errorStr.contains('insufficient_quota')) {
          errorMessage = '⚠️ AI service is temporarily unavailable. Please try again in a moment.';
        } else {
          errorMessage = '❌ Unable to process your message. Please try again.';
        }
      } else if (errorStr.contains('Failed to fetch') || errorStr.contains('ClientException')) {
        errorMessage = '📡 Network error. Please check your internet connection and try again.';
      }
      
      // Show user-friendly error message
      final errorMsg = Message(
        id: const Uuid().v4(),
        text: errorMessage,
        createdAt: DateTime.now(),
        sender: Sender.ai,
      );
      _messages.insert(0, errorMsg);
      await LocalStorage.saveMessages(_messages);
      _isProcessing = false;
      notifyListeners();
    }
  }
}


