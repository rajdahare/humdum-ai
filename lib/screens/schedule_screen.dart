import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_item.dart';
import '../widgets/app_background.dart';

class ScheduleScreen extends StatefulWidget {
  static const routeName = '/schedule';
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _controller = TextEditingController();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get events for a specific day
  List<ScheduleItem> _getEventsForDay(DateTime day, List<ScheduleItem> allItems) {
    return allItems.where((item) {
      return isSameDay(item.time, day);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  @override
  Widget build(BuildContext context) {
    final sched = context.watch<ScheduleProvider>();
    final selectedDayEvents = _getEventsForDay(_selectedDay ?? _focusedDay, sched.items);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule & Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            tooltip: 'Today',
          ),
        ],
      ),
      body: AppBackground(
        child: Column(
          children: [
            // Calendar Widget
            Card(
              margin: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                // Event markers
                eventLoader: (day) {
                  return _getEventsForDay(day, sched.items);
                },
              ),
            ),
            
            // Add Event Input
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'e.g., "Meeting with John at 3pm tomorrow"',
                        hintStyle: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                        prefixIcon: const Icon(Icons.add_circle_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      onSubmitted: (t) async {
                        if (t.trim().isEmpty) return;
                        await context.read<ScheduleProvider>().addFromNaturalLanguage(t.trim());
                        _controller.clear();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Event added!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    onPressed: () async {
                      final t = _controller.text.trim();
                      if (t.isEmpty) return;
                      await context.read<ScheduleProvider>().addFromNaturalLanguage(t);
                      _controller.clear();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Event added!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  )
                ],
              ),
            ),
            
            // Selected Date Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDay != null
                        ? DateFormat('EEEE, MMMM d, y').format(_selectedDay!)
                        : 'Select a date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (selectedDayEvents.isNotEmpty)
                    Chip(
                      label: Text('${selectedDayEvents.length} event${selectedDayEvents.length > 1 ? 's' : ''}'),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Events List for Selected Day
            Expanded(
              child: selectedDayEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No events for this day',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add an event using natural language above',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: selectedDayEvents.length,
                      itemBuilder: (ctx, i) {
                        final event = selectedDayEvents[i];
                        final isPast = event.time.isBefore(DateTime.now());
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: isPast
                              ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                              : null,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                                    : Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isPast ? Icons.history : Icons.event_note,
                                color: isPast
                                    ? Theme.of(context).colorScheme.outline
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              event.title,
                              style: TextStyle(
                                decoration: isPast ? TextDecoration.lineThrough : null,
                                color: isPast ? Theme.of(context).colorScheme.outline : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(DateFormat('h:mm a').format(event.time)),
                                  ],
                                ),
                                if (event.details != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    event.details!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Event?'),
                                    content: Text('Delete "${event.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          context.read<ScheduleProvider>().removeItem(event.id);
                                          Navigator.of(ctx).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Event deleted'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}


