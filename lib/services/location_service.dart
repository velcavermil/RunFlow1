import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // STREAM lokasi (dipakai UI)
  final StreamController<LatLng> _locationController =
      StreamController<LatLng>.broadcast();
  Stream<LatLng> get locationStream => _locationController.stream;

  // STATE
  LatLng? _lastPoint;
  double _totalDistanceKm = 0;
  double get totalDistanceKm => _totalDistanceKm;

  bool isMockMode = false;

  StreamSubscription<Position>? _gpsSub;
  Timer? _mockTimer;

  // ================= START =================
  Future<void> start() async {
    reset();

    if (kIsWeb) {
      isMockMode = true;
      _startMock();
    } else {
      isMockMode = false;
      await _startGPS();
    }
  }

  // ================= STOP =================
  void stop() {
    _gpsSub?.cancel();
    _mockTimer?.cancel();
  }

  void reset() {
    _lastPoint = null;
    _totalDistanceKm = 0;
  }

  // ================= MOBILE GPS =================
  Future<void> _startGPS() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('GPS tidak aktif');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak');
    }

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (pos.accuracy > 50) return;

      _processPoint(LatLng(pos.latitude, pos.longitude));
    });
  }

  // ================= WEB MOCK =================
  void _startMock() {
    double lat = -7.95;
    double lng = 112.61;

    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      lat += 0.00005;
      lng += 0.00005;
      _processPoint(LatLng(lat, lng));
    });
  }

  // ================= SHARED =================
  void _processPoint(LatLng current) {
    if (_lastPoint != null) {
      final meters = const Distance()(_lastPoint!, current);
      if (meters > 3) {
        _totalDistanceKm += meters / 1000;
      }
    }

    _lastPoint = current;
    _locationController.add(current);
  }
}
