import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2010, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focused,
      selectedDayPredicate: (d) => isSameDay(d, _selected),
      onDaySelected: (s, f) => setState(() {
        _selected = s;
        _focused = f;
      }),
      calendarFormat: CalendarFormat.month,
    );
  }
}


