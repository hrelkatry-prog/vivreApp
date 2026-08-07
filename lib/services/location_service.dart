import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if GPS hardware/service is turned ON on device
  Future<bool> isGpsEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Check if Location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Request Location permission from user
  Future<LocationPermission> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await openAppSettings();
      }
      return permission;
    } catch (e) {
      return LocationPermission.denied;
    }
  }

  /// Check both GPS Service AND Permission
  Future<GpsCheckResult> checkGpsAndPermission() async {
    bool serviceEnabled = await isGpsEnabled();
    if (!serviceEnabled) {
      return GpsCheckResult.gpsDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return GpsCheckResult.permissionDenied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return GpsCheckResult.permissionDeniedForever;
    }

    return GpsCheckResult.ready;
  }

  /// Open device Location / GPS Settings
  Future<bool> openGpsSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      return await openAppSettings();
    }
  }

  /// Stream of GPS service status changes (Turned ON / OFF)
  Stream<ServiceStatus> get serviceStatusStream =>
      Geolocator.getServiceStatusStream();

  /// Get Current Position
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }
}

enum GpsCheckResult {
  ready,
  gpsDisabled,
  permissionDenied,
  permissionDeniedForever,
}
