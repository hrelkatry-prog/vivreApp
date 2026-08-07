import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../services/location_service.dart';
import 'webview_screen.dart';

class GpsGateScreen extends StatefulWidget {
  final String? initialUrl;
  const GpsGateScreen({super.key, this.initialUrl});

  @override
  State<GpsGateScreen> createState() => _GpsGateScreenState();
}

class _GpsGateScreenState extends State<GpsGateScreen> with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  StreamSubscription<ServiceStatus>? _statusSubscription;
  bool _isChecking = false;
  GpsCheckResult _currentStatus = GpsCheckResult.gpsDisabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkGpsStatus();
    _listenToGpsStatusChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check GPS when user returns from phone settings
      _checkGpsStatus();
    }
  }

  void _listenToGpsStatusChanges() {
    _statusSubscription = _locationService.serviceStatusStream.listen((status) {
      if (status == ServiceStatus.enabled) {
        _checkGpsStatus();
      }
    });
  }

  Future<void> _checkGpsStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final result = await _locationService.checkGpsAndPermission();

    if (!mounted) return;
    setState(() {
      _currentStatus = result;
      _isChecking = false;
    });

    if (result == GpsCheckResult.ready) {
      // GPS is Active and Permission granted! Proceed to Web App
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: widget.initialUrl ?? AppConstants.systemBaseUrl,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGpsOff = _currentStatus == GpsCheckResult.gpsDisabled;
    final isPermissionDenied = _currentStatus == GpsCheckResult.permissionDenied ||
        _currentStatus == GpsCheckResult.permissionDeniedForever;

    return PopScope(
      canPop: false, // Prevent bypassing by back button
      child: Scaffold(
        backgroundColor: AppConstants.bgDark,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.2,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
                Color(0xFF020617),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Pulsing Warning / Location Icon
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppConstants.dangerRed.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.dangerRed.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.dangerRed.withOpacity(0.25),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.location_off_rounded,
                        color: AppConstants.dangerRed,
                        size: 52,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    isGpsOff
                        ? 'من فضلك قم بتشغيل الموقع (GPS)'
                        : 'إذن تحديد الموقع مطلوب',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Description
                  Text(
                    isGpsOff
                        ? 'تطبيق Vivre يتطلب تشغيل خدمة تحديد الموقع (GPS) لتوجيه مسارات شاحنات التوزيع ومتابعة حركة المبيعات وتوثيق زيارات العملاء بدقة.'
                        : 'يرجى منح تطبيق Vivre إذن الوصول إلى موقع الجهاز لمتابعة العمل وتوثيق فواتير التوزيع.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.slate.shade400,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Primary Action Button (Open Settings)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (isPermissionDenied) {
                          await _locationService.requestLocationPermission();
                        } else {
                          await _locationService.openGpsSettings();
                        }
                        await _checkGpsStatus();
                      },
                      icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white),
                      label: Text(
                        isPermissionDenied
                            ? 'منح إذن الموقع الآن'
                            : 'فتح إعدادات الـ GPS وتفعيله',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryBlue,
                        elevation: 6,
                        shadowColor: AppConstants.primaryBlue.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Secondary Button (Check Again)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isChecking ? null : _checkGpsStatus,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppConstants.accentCyan,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, color: AppConstants.accentCyan),
                      label: Text(
                        _isChecking ? 'جاري الفحص...' : 'إعادة فحص حالة الموقع',
                        style: const TextStyle(
                          color: AppConstants.accentCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppConstants.accentCyan.withOpacity(0.4),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom App Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        color: AppConstants.accentCyan,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Vivre Water Distribution ERP',
                        style: TextStyle(
                          color: Colors.slate.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
