import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../services/location_service.dart';
import 'gps_gate_screen.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  PullToRefreshController? _pullToRefreshController;
  final LocationService _locationService = LocationService();
  Timer? _gpsMonitorTimer;

  double _progress = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUrl = widget.url;

    _initPullToRefresh();
    _startGpsMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsMonitorTimer?.cancel();
    _pullToRefreshController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyGpsPolicy();
    }
  }

  void _initPullToRefresh() {
    _pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: AppConstants.accentCyan,
              backgroundColor: AppConstants.cardBg,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                _webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                _webViewController?.loadUrl(
                  urlRequest: URLRequest(url: await _webViewController?.getUrl()),
                );
              }
            },
          );
  }

  void _startGpsMonitoring() {
    // Periodically verify GPS status every 5 seconds
    _gpsMonitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final isEnabled = await _locationService.isGpsEnabled();
      if (!isEnabled && mounted) {
        _enforceGpsGate();
      }
    });
  }

  Future<void> _verifyGpsPolicy() async {
    final result = await _locationService.checkGpsAndPermission();
    if (result != GpsCheckResult.ready) {
      _enforceGpsGate();
    }
  }

  void _enforceGpsGate() {
    if (!mounted) return;
    _gpsMonitorTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GpsGateScreen(
          initialUrl: _currentUrl.isNotEmpty ? _currentUrl : AppConstants.systemBaseUrl,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      _webViewController!.goBack();
      return false;
    }
    return await _showExitConfirmationDialog();
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppConstants.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.logout_rounded, color: AppConstants.accentCyan),
                SizedBox(width: 10),
                Text(
                  'الخروج من التطبيق',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'هل أنت متأكد من رغبتك في إغلاق تطبيق Vivre؟',
              style: TextStyle(color: AppConstants.textSlate300, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء', style: TextStyle(color: AppConstants.textSlate400)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.dangerRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('نعم، خروج', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Bulletproof handler for external navigation intents, Google Maps, Navigation, Calls & WhatsApp
  Future<bool> _handleExternalUrl(Uri uri) async {
    final urlString = uri.toString();
    final scheme = uri.scheme.toLowerCase();

    // 1. Android Intent Protocol (intent://...)
    if (scheme == 'intent') {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        }

        // Try extracting fallback HTTP/HTTPS URL from intent
        final match = RegExp(r'(?:browser_fallback_url|link)=([^;]+)').firstMatch(urlString);
        if (match != null) {
          final fallbackUrl = Uri.parse(Uri.decodeComponent(match.group(1)!));
          await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
          return true;
        }
      } catch (e) {
        debugPrint('Error handling intent URL: $e');
      }
      return true; // Cancel webview load regardless so it doesn't throw ERR_UNKNOWN_URL_SCHEME
    }

    // 2. Identify Maps, Routes, GPS Navigation, Waze
    final isMaps = scheme == 'geo' ||
        scheme == 'google.navigation' ||
        scheme == 'waze' ||
        scheme == 'maps' ||
        uri.host.contains('maps.google.') ||
        (uri.host.contains('google.com') && uri.path.contains('maps')) ||
        uri.host.contains('maps.app.goo.gl') ||
        uri.host.contains('goo.gl') ||
        uri.host.contains('waze.com') ||
        uri.host.contains('maps.apple.com');

    // 3. Identify Phone calls, WhatsApp, Email, SMS
    final isCommunication = scheme == 'tel' ||
        scheme == 'mailto' ||
        scheme == 'sms' ||
        scheme == 'whatsapp' ||
        uri.host.contains('whatsapp.com') ||
        uri.host.contains('wa.me');

    // 4. Any Non-HTTP scheme (deep links, external apps)
    final isNonHttpScheme = scheme.isNotEmpty &&
        scheme != 'http' &&
        scheme != 'https' &&
        scheme != 'about' &&
        scheme != 'data' &&
        scheme != 'javascript';

    if (isMaps || isCommunication || isNonHttpScheme) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        debugPrint('Error launching external URL: $e');
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      return true; // Intercepted and handled
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.bgDark,
        body: SafeArea(
          child: Stack(
            children: [
              // InAppWebView
              if (!_hasError)
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                  initialSettings: InAppWebViewSettings(
                    useShouldOverrideUrlLoading: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    javaScriptEnabled: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    supportMultipleWindows: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    geolocationEnabled: true, // Enable HTML5 Geolocation API
                    useOnDownloadStart: true,
                    userAgent: AppConstants.customUserAgent,
                    transparentBackground: false,
                    supportZoom: true,
                    builtInZoomControls: false,
                    displayZoomControls: false,
                  ),
                  pullToRefreshController: _pullToRefreshController,
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                      if (url != null) _currentUrl = url.toString();
                    });
                  },
                  onLoadStop: (controller, url) async {
                    _pullToRefreshController?.endRefreshing();
                    setState(() {
                      _isLoading = false;
                      if (url != null) _currentUrl = url.toString();
                    });
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      _pullToRefreshController?.endRefreshing();
                    }
                    setState(() {
                      _progress = progress / 100;
                      if (progress == 100) _isLoading = false;
                    });
                  },
                  onReceivedError: (controller, request, error) {
                    _pullToRefreshController?.endRefreshing();
                    
                    // Ignore ERR_UNKNOWN_URL_SCHEME because external intents/maps are handled via url_launcher
                    final desc = error.description.toLowerCase();
                    if (desc.contains('err_unknown_url_scheme') ||
                        desc.contains('unknown_url_scheme') ||
                        error.type == WebResourceErrorType.UNKNOWN_URL_SCHEME) {
                      final uri = request.url;
                      if (uri != null) {
                        _handleExternalUrl(uri);
                      }
                      return;
                    }

                    if (request.isForMainFrame ?? true) {
                      setState(() {
                        _hasError = true;
                        _errorMessage = error.description;
                      });
                    }
                  },
                  onGeolocationPermissionsShowPrompt: (controller, origin) async {
                    // Automatically grant geolocation permission to the trusted host
                    return GeolocationPermissionShowPromptResponse(
                      origin: origin,
                      allow: true,
                      retain: true,
                    );
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final uri = navigationAction.request.url;
                    if (uri == null) return NavigationActionPolicy.ALLOW;

                    final handled = await _handleExternalUrl(uri);
                    if (handled) {
                      return NavigationActionPolicy.CANCEL;
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onCreateWindow: (controller, createWindowAction) async {
                    final uri = createWindowAction.request.url;
                    if (uri != null) {
                      await _handleExternalUrl(uri);
                    }
                    return false; // Handled externally, don't create child webview
                  },
                ),

              // Linear Progress Bar during navigation
              if (_isLoading && _progress < 1.0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.accentCyan),
                    minHeight: 3,
                  ),
                ),

              // Error View (Network disconnected)
              if (_hasError)
                Container(
                  color: AppConstants.bgDark,
                  padding: const EdgeInsets.all(28.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppConstants.warningOrange.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppConstants.warningOrange.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.wifi_off_rounded,
                              color: AppConstants.warningOrange,
                              size: 42,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'تعذر الاتصال بالخادم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'يرجى التأكد من اتصال الهاتف بالإنترنت والمحاولة مجدداً.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppConstants.textSlate400, fontSize: 13, height: 1.5),
                        ),
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: AppConstants.textSlate600, fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 200,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                                _isLoading = true;
                              });
                              _webViewController?.reload();
                            },
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                            label: const Text(
                              'إعادة المحاولة',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
