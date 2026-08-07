import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

enum GpsCheckResult {
  ready,
  gpsDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if GPS hardware/service is turned ON on device
  Future<bool> isGpsEnabled() async {
    try {
      final status = await Permission.location.serviceStatus;
      return status.isEnabled;
    } catch (e) {
      return true;
    }
  }

  /// Check if Location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Request Location permission from user
  Future<PermissionStatus> requestLocationPermission() async {
    try {
      PermissionStatus status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
      }
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return status;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  /// Check both GPS Service AND Permission
  Future<GpsCheckResult> checkGpsAndPermission() async {
    bool serviceEnabled = await isGpsEnabled();
    if (!serviceEnabled) {
      return GpsCheckResult.gpsDisabled;
    }

    PermissionStatus status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          return GpsCheckResult.permissionDeniedForever;
        }
        return GpsCheckResult.permissionDenied;
      }
    }

    return GpsCheckResult.ready;
  }

  /// Open device Location / GPS Settings
  Future<bool> openGpsSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      return false;
    }
  }
}
