import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_item.dart';
import '../services/api_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final List<ScheduleItem> _items = [];
  bool _isLoading = false;
  
  List<ScheduleItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  ScheduleProvider() {
    loadSchedule();
  }

  Future<void> loadSchedule() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final res = await ApiService.get('/schedule/list');
      _items.clear();
      
      debugPrint('Schedule API response: $res');
      debugPrint('Schedule API response type: ${res.runtimeType}');
      
      // Handle response - parse based on actual type
      final List<dynamic> scheduleList = [];
      
      // Check actual runtime type and handle accordingly
      try {
        if (res is List) {
          debugPrint('Response is List, processing ${res.length} items');
          final list = res as List;
          scheduleList.addAll(list);
        } else if (res is Map) {
          debugPrint('Response is Map, not List');
          // Backend returns List directly, if we get Map something is wrong
          // But still try to handle it gracefully
        } else {
          debugPrint('Unexpected response type: ${res.runtimeType}');
        }
      } catch (e) {
        debugPrint('Error handling response: $e');
      }
      
      debugPrint('Final schedule list size: ${scheduleList.length}');
      
      // Process the schedule list
      for (final item in scheduleList) {
        try {
          if (item is Map) {
            // Backend returns 'datetime' field, not 'time'
            final timeStr = item['datetime']?.toString() ?? item['time']?.toString() ?? '';
            final parsedTime = DateTime.tryParse(timeStr);
            
            if (parsedTime != null) {
              final scheduleItem = ScheduleItem(
                id: item['id']?.toString() ?? const Uuid().v4(),
                title: item['title']?.toString() ?? 'Event',
                time: parsedTime,
                details: item['note']?.toString() ?? item['details']?.toString(),
              );
              _items.add(scheduleItem);
            } else {
              debugPrint('Could not parse time for item: $item');
            }
          }
        } catch (e) {
          debugPrint('Error processing schedule item: $e');
        }
      }
      
      // Sort by time (earliest first)
      _items.sort((a, b) => a.time.compareTo(b.time));
      
      debugPrint('Loaded ${_items.length} schedule items');
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      // Don't rethrow - just log and continue with empty list
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFromNaturalLanguage(String nl) async {
    try {
      final res = await ApiService.post('/schedule/add', {'text': nl});
      final title = (res['title'] ?? 'Reminder').toString();
      final timeStr = (res['time'] ?? DateTime.now().toIso8601String()).toString();
      final item = ScheduleItem(
        id: const Uuid().v4(),
        title: title,
        time: DateTime.tryParse(timeStr) ?? DateTime.now(),
        details: res['details']?.toString(),
      );
      _items.add(item);
      // Sort by time (earliest first)
      _items.sort((a, b) => a.time.compareTo(b.time));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding schedule item: $e');
      rethrow;
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearPastEvents() {
    final now = DateTime.now();
    _items.removeWhere((item) => item.time.isBefore(now));
    notifyListeners();
  }
}


