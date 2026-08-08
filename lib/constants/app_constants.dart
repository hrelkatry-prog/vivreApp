import 'package:flutter/material.dart';

class AppConstants {
  // App Identity
  static const String appName = 'Vivre';
  static const String appFullName = 'Vivre | نظام إدارة وتوزيع المياه';
  static const String appVersion = '1.0.32';
  static const int appBuildNumber = 32;

  // System Base URLs & Endpoints
  static const String systemBaseUrl = 'https://w.rseha.com/';
  static const String versionCheckUrl = 'https://w.rseha.com/api/app/version';
  static const String githubLatestReleaseApi = 'https://api.github.com/repos/hrelkatry-prog/vivreApp/releases/latest';
  static const String fallbackApkDownloadUrl = 'https://github.com/hrelkatry-prog/vivreApp/releases/latest';

  // Brand Colors
  static const Color primaryBlue = Color(0xFF0284C7); // Sky 600
  static const Color primaryDark = Color(0xFF0F172A); // Slate 900
  static const Color accentCyan = Color(0xFF06B6D4);  // Cyan 500
  static const Color bgDark = Color(0xFF020617);      // Slate 950
  static const Color cardBg = Color(0xFF1E293B);      // Slate 800
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  // Modern Text Colors
  static const Color textSlate300 = Color(0xFFCBD5E1);
  static const Color textSlate400 = Color(0xFF94A3B8);
  static const Color textSlate500 = Color(0xFF64748B);
  static const Color textSlate600 = Color(0xFF475569);

  // User Agent
  static const String customUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 VivreApp/1.0.32';
}
