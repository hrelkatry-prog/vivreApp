import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_constants.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Modern transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppConstants.bgDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VivreApp());
}

class VivreApp extends StatelessWidget {
  const VivreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Default RTL & Arabic Localization
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConstants.bgDark,
        primaryColor: AppConstants.primaryBlue,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryBlue,
          secondary: AppConstants.accentCyan,
          surface: AppConstants.cardBg,
          error: AppConstants.dangerRed,
        ),
        textTheme: GoogleFonts.cairoTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}
