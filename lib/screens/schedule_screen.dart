import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule_model.dart';
import '../services/schedule_storage.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<ScheduleModel> schedules = [];
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    final data = await ScheduleStorage.getSchedules();
    setState(() => schedules = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Running Schedule',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= CALENDAR =================
            _Calendar(
              currentDate: now,
              schedules: schedules,
            ),

            const SizedBox(height: 24),

            const Text(
              'Jadwal Running',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: schedules.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada jadwal',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        final s = schedules[index];
                        return _ScheduleCard(
                          schedule: s,
                          onDelete: () => _confirmDelete(s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // ================= FLOATING BUTTON =================
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2A5298),
        onPressed: () => _showAddSchedule(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ================= DELETE =================
  Future<void> _confirmDelete(ScheduleModel schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: const Text(
          'Apakah kamu yakin ingin menghapus jadwal lari ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ScheduleStorage.deleteSchedule(schedule);
      loadSchedules();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil dihapus')),
      );
    }
  }

  // ================= ADD SCHEDULE =================
  void _showAddSchedule(BuildContext context) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final typeController = TextEditingController();
    final distanceController = TextEditingController();

    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _InputField(
                label: 'Date',
                icon: Icons.calendar_today,
                controller: dateController,
                onTap: () async {
                  selectedDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (selectedDate != null) {
                    dateController.text =
                        DateFormat('dd MMM yyyy').format(selectedDate!);
                  }
                },
              ),

              _InputField(
                label: 'Time',
                icon: Icons.access_time,
                controller: timeController,
                onTap: () async {
                  selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selectedTime != null) {
                    timeController.text = selectedTime!.format(context);
                  }
                },
              ),

              _InputField(
                label: 'Run Type',
                icon: Icons.directions_run,
                controller: typeController,
              ),

              _InputField(
                label: 'Distance (km)',
                icon: Icons.straighten,
                controller: distanceController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A5298),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () async {
                    if (selectedDate == null ||
                        selectedTime == null ||
                        distanceController.text.isEmpty) {
                      return;
                    }

                    final dateTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );

                    final schedule = ScheduleModel(
                      date: dateTime,
                      runType: typeController.text,
                      distance:
                          double.tryParse(distanceController.text) ?? 0,
                    );

                    await ScheduleStorage.saveSchedule(schedule);
                    loadSchedules();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save Schedule',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===================== CALENDAR =====================
class _Calendar extends StatelessWidget {
  final DateTime currentDate;
  final List<ScheduleModel> schedules;

  const _Calendar({
    required this.currentDate,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(currentDate.year, currentDate.month);
    final firstDay =
        DateTime(currentDate.year, currentDate.month, 1).weekday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(currentDate),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + firstDay - 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < firstDay - 1) return const SizedBox();

              final day = index - firstDay + 2;
              final date = DateTime(
                currentDate.year,
                currentDate.month,
                day,
              );

              final isToday =
                  DateUtils.isSameDay(date, DateTime.now());
              final hasSchedule = schedules.any(
                (s) => DateUtils.isSameDay(s.date, date),
              );

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFF2A5298)
                      : hasSchedule
                          ? const Color(0xFF8EE6B7)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.black,
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===================== CARD =====================
class _ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Color(0xFF2A5298)),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('dd MMM yyyy • HH:mm').format(schedule.date)} | '
                  '${schedule.distance} km',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  schedule.runType,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;

  const _InputField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: onTap != null,
        keyboardType: keyboardType,
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
