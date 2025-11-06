import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/message.dart';

class LocalStorage {
  static const String chatBoxName = 'chat_cache_v1';

  static Future<void> init() async {
    await Hive.openBox<String>(chatBoxName);
  }

  static Future<void> saveMessages(List<Message> messages) async {
    final box = Hive.box<String>(chatBoxName);
    final trimmed = messages.take(20).toList();
    final data = jsonEncode(trimmed.map((m) => m.toJson()).toList());
    await box.put('recent', data);
  }

  static List<Message> loadMessages() {
    final box = Hive.box<String>(chatBoxName);
    final data = box.get('recent');
    if (data == null) return [];
    final list = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
    return list.map(Message.fromJson).toList();
  }

  static Future<void> clearMessages() async {
    final box = Hive.box<String>(chatBoxName);
    await box.delete('recent');
  }

  static Future<void> saveAIUsage(Map<String, dynamic> usage) async {
    final box = Hive.box<String>(chatBoxName);
    await box.put('ai_usage', jsonEncode(usage));
  }

  static Map<String, dynamic> loadAIUsage() {
    final box = Hive.box<String>(chatBoxName);
    final data = box.get('ai_usage');
    if (data == null) return {};
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<void> saveConversationHistory(List<Map<String, String>> history) async {
    final box = Hive.box<String>(chatBoxName);
    await box.put('conversation_history', jsonEncode(history));
  }

  static List<Map<String, String>> loadConversationHistory() {
    final box = Hive.box<String>(chatBoxName);
    final data = box.get('conversation_history');
    if (data == null) return [];
    try {
      final list = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      final history = list.map((m) => m.map((k, v) => MapEntry(k, v.toString()))).toList();
      
      // IMPORTANT: Trim history on load to prevent issues
      // Keep only last 20 messages
      if (history.length > 20) {
        print('Trimming loaded history from ${history.length} to 20');
        return history.sublist(history.length - 20);
      }
      
      return history;
    } catch (e) {
      print('Error loading conversation history: $e');
      // If corrupted, return empty
      return [];
    }
  }

  static Future<void> clearConversationHistory() async {
    final box = Hive.box<String>(chatBoxName);
    await box.delete('conversation_history');
  }

  // Complete reset - use if there's corrupted data
  static Future<void> clearAll() async {
    final box = Hive.box<String>(chatBoxName);
    await box.clear();
    print('LocalStorage: All data cleared');
  }
}


