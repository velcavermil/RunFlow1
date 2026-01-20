import 'package:flutter/material.dart';
import '../services/run_storage.dart';

class WebDashboard extends StatelessWidget {
  const WebDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RunFlow Dashboard')),
      body: FutureBuilder(
        future: RunStorage.getRuns(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final runs = snapshot.data!;
          if (runs.isEmpty) {
            return const Center(child: Text('Belum ada data lari'));
          }

          return ListView.builder(
            itemCount: runs.length,
            itemBuilder: (_, i) {
              final r = runs[i];
              return ListTile(
                leading: const Icon(Icons.directions_run),
                title: Text('${r.distance.toStringAsFixed(2)} km'),
                subtitle: Text(r.formattedDuration),
              );
            },
          );
        },
      ),
    );
  }
}
