import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event.dart';
import '../../widgets/responsive_scaffold.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isMonthView = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final calProvider = context.watch<CalendarProvider>();
    final selectedEvents = calProvider.getEventsForDay(_selectedDay ?? _focusedDay);
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    final calendarWidget = Container(
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2027, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _isMonthView ? CalendarFormat.month : CalendarFormat.week,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: calProvider.getEventsForDay,
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          weekendTextStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          selectedDecoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.3), shape: BoxShape.circle),
          todayTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
          outsideDaysVisible: false,
          markerDecoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
          markerSize: 5,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
          formatButtonTextStyle: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold),
          titleCentered: true,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF94A3B8), size: 20),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          weekendStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _isMonthView = format == CalendarFormat.month;
          });
        },
        onPageChanged: (focused) => setState(() => _focusedDay = focused),
      ),
    );

    final eventListWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            _selectedDay != null ? DateFormat('MMMM d, yyyy').format(_selectedDay!) : 'Select a day',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (!isMobile)
            ElevatedButton.icon(
              onPressed: () => _showAddEventDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Event'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
        ]),
        const SizedBox(height: 16),
        if (selectedEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No events for this day', style: TextStyle(color: Color(0xFF64748B)))),
          )
        else
          ...selectedEvents.map((e) => _EventCard(event: e)),
      ],
    );

    return ResponsiveScaffold(
      title: 'Calendar',
      currentRoute: '/calendar',
      floatingActionButton: isMobile ? FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: isMobile 
          ? Column(
              children: [
                calendarWidget,
                const SizedBox(height: 24),
                eventListWidget,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: calendarWidget),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: eventListWidget),
              ],
            ),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => _AddEventDialog(selectedDay: _selectedDay ?? _focusedDay));
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFF6366F1), width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        if (event.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(event.description, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(event.createdBy, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const Spacer(),
          const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(DateFormat('h:mm a').format(event.date), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _AddEventDialog extends StatefulWidget {
  final DateTime selectedDay;
  const _AddEventDialog({required this.selectedDay});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;
    final user = context.read<AuthProvider>().currentUser!;
    final calProvider = context.read<CalendarProvider>();
    calProvider.addEvent(CalendarEvent(
      id: calProvider.newId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      date: widget.selectedDay,
      createdBy: user.name,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Event — ${DateFormat('MMM d, yyyy').format(widget.selectedDay)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _field('Title', _titleController, 'Event title'),
            const SizedBox(height: 16),
            _field('Description', _descController, 'Optional description', maxLines: 3),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B)))),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Add Event'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, maxLines: maxLines, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF475569)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      )),
    ]);
  }
}
