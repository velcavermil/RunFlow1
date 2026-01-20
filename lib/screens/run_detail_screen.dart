import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/run_model.dart';

class RunDetailScreen extends StatelessWidget {
  final RunModel run;

  const RunDetailScreen({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final minutes = run.duration ~/ 60;
    final seconds = run.duration % 60;

    final pace = run.distance > 0
        ? (run.duration / 60 / run.distance)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Lari')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoCard(
              'Tanggal',
              DateFormat('dd MMM yyyy, HH:mm').format(run.date),
            ),
            _infoCard(
              'Jarak',
              '${run.distance.toStringAsFixed(2)} km',
            ),
            _infoCard(
              'Durasi',
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            ),
            _infoCard(
              'Pace Rata-rata',
              pace > 0 ? '${pace.toStringAsFixed(2)} min/km' : '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
