import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/run_model.dart';
import '../models/user_model.dart';
import '../models/schedule_model.dart';

import '../services/run_storage.dart';
import '../services/user_storage.dart';
import '../services/schedule_storage.dart';

import 'run_screen.dart';
import 'history_screen.dart';
import 'schedule_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ================= STATE =================
  double totalDistance = 0;
  int totalRuns = 0;
  double avgPace = 0;
  int avgDuration = 0;

  UserModel? user;
  ScheduleModel? upcomingRun;

  bool isLoading = true;
  bool animate = false;
  bool pressed = false;

  @override
  void initState() {
    super.initState();
    _initLoad();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => animate = true);
    });
  }

  // ================= INIT LOAD =================
  Future<void> _initLoad() async {
    await Future.wait([
      loadUser(),
      loadStats(),
      loadUpcomingRun(),
    ]);

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // ================= USER =================
  Future<void> loadUser() async {
    final u = await UserStorage.getUser();
    if (mounted) setState(() => user = u);
  }

  // ================= UPCOMING RUN =================
  Future<void> loadUpcomingRun() async {
    final schedules = await ScheduleStorage.getSchedules();
    final now = DateTime.now();

    final upcoming = schedules
        .where((s) => s.date.isAfter(now))
        .toList();

    if (upcoming.isEmpty) {
      if (mounted) setState(() => upcomingRun = null);
      return;
    }

    upcoming.sort((a, b) => a.date.compareTo(b.date));
    if (mounted) setState(() => upcomingRun = upcoming.first);
  }

  // ================= STATS =================
  Future<void> loadStats() async {
    final runs = await RunStorage.getRuns();
    final now = DateTime.now();

    final monthlyRuns = runs.where((r) =>
        r.date.month == now.month &&
        r.date.year == now.year).toList();

    if (monthlyRuns.isEmpty) {
      if (mounted) {
        setState(() {
          totalDistance = 0;
          totalRuns = 0;
          avgPace = 0;
          avgDuration = 0;
        });
      }
      return;
    }

    double distanceSum = 0;
    int durationSum = 0;

    for (var run in monthlyRuns) {
      distanceSum += run.distance;
      durationSum += run.duration;
    }

    if (mounted) {
      setState(() {
        totalRuns = monthlyRuns.length;
        totalDistance = distanceSum;
        avgDuration = durationSum ~/ totalRuns;
        avgPace =
            distanceSum > 0 ? (durationSum / 60 / distanceSum) : 0;
      });
    }
  }

  String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('RunFlow', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note, color: Colors.black),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              );
              loadUpcomingRun(); // refresh setelah balik
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onSelected: (value) async {
              if (value == 'logout') {
                await UserStorage.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // ================= BODY =================
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2A5298),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AnimatedOpacity(
                    opacity: animate ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: AnimatedSlide(
                      offset: animate
                          ? Offset.zero
                          : const Offset(0, 0.1),
                      duration: const Duration(milliseconds: 600),
                      child: _heroCard(),
                    ),
                  ),

                  if (upcomingRun != null) ...[
                    const SizedBox(height: 16),
                    _upcomingRunCard(),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Pace Rata-rata',
                          value: avgPace > 0
                              ? avgPace.toStringAsFixed(2)
                              : '--',
                          subtitle: 'min / km',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Durasi Rata-rata',
                          value: formatDuration(avgDuration),
                          subtitle: 'Average',
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTapDown: (_) => setState(() => pressed = true),
                    onTapUp: (_) => setState(() => pressed = false),
                    onTapCancel: () =>
                        setState(() => pressed = false),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RunScreen()),
                      );
                      loadStats();
                    },
                    child: AnimatedScale(
                      scale: pressed ? 0.96 : 1,
                      duration:
                          const Duration(milliseconds: 120),
                      child: Container(
                        height: 68,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A5298),
                          borderRadius:
                              BorderRadius.circular(40),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'START RUN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const HistoryScreen()),
                      );
                    },
                    child: const Text('Lihat Riwayat'),
                  ),
                ],
              ),
            ),
    );
  }

  // ================= HERO CARD =================
  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null)
            Text(
              'Hi, ${user!.name} 👋',
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 8),
          Text(
            totalDistance.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 46,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Total Distance (This Month)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            '$totalRuns Lari Bulan Ini',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ================= UPCOMING RUN CARD =================
  Widget _upcomingRunCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: Color(0xFF2A5298)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Run',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('dd MMM yyyy • HH:mm').format(upcomingRun!.date)} | '
                    '${upcomingRun!.distance} km',
                    style:
                        const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    upcomingRun!.runType,
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

// ================= STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(subtitle,
              style: const TextStyle(color: Colors.black38)),
        ],
      ),
    );
  }
}
