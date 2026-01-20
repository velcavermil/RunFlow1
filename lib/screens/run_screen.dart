import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/run_model.dart';
import '../services/run_storage.dart';

class RunScreen extends StatefulWidget {
  const RunScreen({super.key});

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  late DateTime startTime;

  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  int elapsedSeconds = 0;
  bool isPaused = false;

  double distanceKm = 0.0;
  LatLng? lastPosition;
  final List<LatLng> routePoints = [];

  final distanceCalc = Distance();

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    startTimer();
    startLocationTracking();
  }

  // ================= TIMER =================
  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsedSeconds++;
      });
    });
  }

  // ================= GPS TRACKING =================
  void startLocationTracking() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) return;

  _positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    ),
  ).listen((Position position) {
    // ================= FILTER 1: AKURASI =================
    if (position.accuracy > 20) return;

    // ================= FILTER 2: KECEPATAN =================
    if (position.speed < 0.5) return;

    final current = LatLng(position.latitude, position.longitude);

    if (lastPosition != null) {
      final meters = distanceCalc(lastPosition!, current);

      // ================= FILTER 3: JARAK MINIMUM =================
      if (meters < 8) return;

      distanceKm += meters / 1000;
    }

    lastPosition = current;
    routePoints.add(current);

    setState(() {});
  });
}


  // ================= CONTROLS =================
  void pauseRun() {
    _timer?.cancel();
    _positionStream?.pause();
    setState(() => isPaused = true);
  }

  void resumeRun() {
    startTimer();
    _positionStream?.resume();
    setState(() => isPaused = false);
  }

  void stopRun() async {
    _timer?.cancel();
    await _positionStream?.cancel();

    final run = RunModel(
      distance: distanceKm,
      duration: elapsedSeconds,
      date: startTime,
    );

    await RunStorage.saveRun(run);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;

    return Scaffold(
      body: Stack(
        children: [
          // ================= MAP =================
          FlutterMap(
            options: MapOptions(
              center: routePoints.isNotEmpty
                  ? routePoints.last
                  : LatLng(-7.95, 112.61),
              zoom: 17,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.running_tracker',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4,
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),

          // ================= DISTANCE CARD =================
          Positioned(
            top: 90,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF2A4F7A),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Text(
                    distanceKm.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text('km',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  const Text(
                    'Distance',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // ================= INFO BAR =================
          Positioned(
            bottom: 150,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF2A4F7A),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white24,
                  ),
                  Text(
                    distanceKm > 0
                        ? '${(elapsedSeconds / 60 / distanceKm).toStringAsFixed(2)} /km'
                        : '-- /km',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // ================= ACTION BUTTONS =================
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isPaused ? resumeRun : pauseRun,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: isPaused
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFF5B82E),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        size: 32,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: stopRun,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE94B4B),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(Icons.stop,
                          size: 32, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

