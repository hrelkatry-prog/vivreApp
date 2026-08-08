import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../services/update_service.dart';

class UpdateGateScreen extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback? onDismiss;

  const UpdateGateScreen({
    super.key,
    required this.updateInfo,
    this.onDismiss,
  });

  Future<void> _launchDownloadUrl(BuildContext context) async {
    final url = Uri.parse(
      updateInfo.downloadUrl.isNotEmpty
          ? updateInfo.downloadUrl
          : AppConstants.fallbackApkDownloadUrl,
    );

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppConstants.dangerRed,
            content: Text(
              'تعذر فتح رابط التحميل: $e',
              style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForce = updateInfo.isForceUpdate;

    return PopScope(
      canPop: !isForce,
      onPopInvoked: (didPop) {
        if (didPop && onDismiss != null) {
          onDismiss!();
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.bgDark,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                Color(0xFF0F2B48), // Deep Cyan/Navy
                Color(0xFF0F172A), // Slate 900
                Color(0xFF020617), // Slate 950
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Animated-style Update Icon Container
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF10B981), // Emerald 500
                            Color(0xFF06B6D4), // Cyan 500
                            Color(0xFF0284C7), // Sky 600
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.accentCyan.withOpacity(0.4),
                            blurRadius: 36,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.system_update_alt_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Update Title
                    Text(
                      updateInfo.releaseTitle.isNotEmpty
                          ? updateInfo.releaseTitle
                          : 'تحديث جديد متوفر للتطبيق!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Version Badges Comparison
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppConstants.textSlate600),
                          ),
                          child: Text(
                            'الإصدار الحالي: v${AppConstants.appVersion}',
                            style: const TextStyle(color: AppConstants.textSlate400, fontSize: 11),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded, color: AppConstants.accentCyan, size: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.accentCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppConstants.accentCyan),
                          ),
                          child: Text(
                            'الإصدار الجديد: v${updateInfo.latestVersion}',
                            style: const TextStyle(
                              color: AppConstants.accentCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Release Notes Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppConstants.cardBg.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: AppConstants.warningOrange, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'ما الجديد في هذا التحديث؟',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            updateInfo.releaseNotes.isNotEmpty
                                ? updateInfo.releaseNotes
                                : '• تحسين التوجيه الملاحي وتتبع خرائط جوجل.\n• تسريع وتثبيت استقرار أداء التطبيق.',
                            style: const TextStyle(
                              color: AppConstants.textSlate300,
                              fontSize: 12.5,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Big Update / Download Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchDownloadUrl(context),
                        icon: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
                        label: const Text(
                          'تحميل وتحديث التطبيق الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.successGreen,
                          elevation: 8,
                          shadowColor: AppConstants.successGreen.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Dismiss / Later Button (If not mandatory)
                    if (!isForce && onDismiss != null)
                      TextButton(
                        onPressed: onDismiss,
                        child: const Text(
                          'المتابعة بالإصدار الحالي وتحديث لاحقاً',
                          style: TextStyle(color: AppConstants.textSlate400, fontSize: 12),
                        ),
                      )
                    else if (isForce)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, color: AppConstants.dangerRed.withOpacity(0.8), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'هذا التحديث إلزامي لضمان دقة مزامنة الطلبات والخرائط',
                            style: TextStyle(
                              color: AppConstants.dangerRed.withOpacity(0.9),
                              fontSize: 11,
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
      ),
    );
  }
}
