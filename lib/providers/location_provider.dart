import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

/// Provider for managing location state
class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String _locationName = 'Mencari lokasi...';
  bool _isLoading = false;
  String? _errorMessage;

  Position? get currentPosition => _currentPosition;
  String get locationName => _locationName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Request location permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    
    final locationStatus = await Permission.location.request();
    return !locationStatus.isDenied;
  }

  /// Set manual location
  void setManualLocation({
    required double latitude,
    required double longitude,
    required String locationName,
  }) {
    _currentPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    _locationName = locationName;
    _errorMessage = null;
    notifyListeners();
  }

  /// Get current GPS location
  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS tidak aktif. Mohon aktifkan lokasi.');
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Buka pengaturan untuk mengaktifkan.');
      }

      // Get position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Reverse Geocoding
      await _reverseGeocode();

    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Location error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Reverse geocode current position to get location name
  Future<void> _reverseGeocode() async {
    if (_currentPosition == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _locationName = '${place.locality ?? place.subAdministrativeArea ?? ''}, ${place.country ?? ''}';
      }
    } catch (e) {
      _locationName = 'Lat: ${_currentPosition!.latitude.toStringAsFixed(2)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(2)}';
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
