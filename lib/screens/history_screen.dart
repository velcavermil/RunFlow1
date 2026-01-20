import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/run_model.dart';
import '../services/run_storage.dart';
import 'run_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<RunModel> runs = [];

  @override
  void initState() {
    super.initState();
    loadRuns();
  }

  Future<void> loadRuns() async {
    final data = await RunStorage.getRuns();
    setState(() {
      runs = data.reversed.toList(); // terbaru di atas
    });
  }

  @override
  Widget build(BuildContext context) {
    final RunModel? latestRun = runs.isNotEmpty ? runs.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Run History',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.tune, color: Colors.black),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= HERO HISTORY CARD =================
          if (latestRun != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RunDetailScreen(run: latestRun),
                  ),
                );
              },
              child: _HeroHistoryCard(run: latestRun),
            ),

          const SizedBox(height: 20),

          // ================= MINI STATS =================
          if (latestRun != null)
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.directions_run,
                    label: 'Avg Pace',
                    value: latestRun.distance > 0
                        ? '${(latestRun.duration / 60 / latestRun.distance).toStringAsFixed(2)} /km'
                        : '-',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.access_time,
                    label: 'Duration',
                    value: _formatDuration(latestRun.duration),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _MiniStat(
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: '—',
                  ),
                ),
              ],
            ),

          const SizedBox(height: 28),

          // ================= OLD HISTORY LIST =================
          for (int i = 1; i < runs.length; i++)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RunDetailScreen(run: runs[i]),
                  ),
                );
              },
              child: _HistoryRow(
                text:
                    '${DateFormat('dd MMM yyyy').format(runs[i].date)}  |  '
                    '${runs[i].distance.toStringAsFixed(2)} km  |  '
                    '${_formatDuration(runs[i].duration)}',
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ================= HERO CARD =================
class _HeroHistoryCard extends StatelessWidget {
  final RunModel run;

  const _HeroHistoryCard({required this.run});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3C72),
            Color(0xFF2A5298),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 110,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.map, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  DateFormat('dd MMM yyyy\nHH:mm').format(run.date),
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${run.distance.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Distance',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= MINI STAT =================
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ================= HISTORY ROW =================
class _HistoryRow extends StatelessWidget {
  final String text;

  const _HistoryRow({required this.text});

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
      child: Text(text),
    );
  }
}
