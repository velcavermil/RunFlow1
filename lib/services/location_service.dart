import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // STREAM
  final StreamController<LatLng> _locationController =
      StreamController<LatLng>.broadcast();
  Stream<LatLng> get locationStream => _locationController.stream;

  LatLng? _lastPoint;
  double _totalDistanceKm = 0;
  double get totalDistanceKm => _totalDistanceKm;

  StreamSubscription<Position>? _gpsSub;

  // START
  Future<void> start() async {
    stop();     // pastikan tidak ada stream lama
    reset();    // reset distance dan lastPoint
    await _startGPS();
  }

  // STOP
  void stop() {
    _gpsSub?.cancel();
  }

  void reset() {
    _lastPoint = null;
    _totalDistanceKm = 0;
  }

  // START GPS
  Future<void> _startGPS() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception("GPS tidak aktif");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception("Izin lokasi ditolak");
    }

    // Trigger GPS (Wajib di Web)
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    // kirim titik pertama TANPA FILTER
    _processPoint(LatLng(pos.latitude, pos.longitude));

    // Stream GPS
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((pos) {
      if (!kIsWeb) {
        if (pos.accuracy > 50) return;
      }

      _processPoint(LatLng(pos.latitude, pos.longitude));
    });
  }

  // PROCESS POINT
  void _processPoint(LatLng current) {
    // TITIK PERTAMA → SELALU DITERIMA
    if (_lastPoint == null) {
      _lastPoint = current;
      _locationController.add(current);
      return;
    }

    final meters = const Distance()(_lastPoint!, current);

    // Filter normal
    if (meters < 1 || meters > 80) return;

    _totalDistanceKm += meters / 1000;

    _lastPoint = current;
    _locationController.add(current);
  }
}
