import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotife/routes/app_routes.dart';
import 'package:spotife/service/api/auth_service.dart';
import 'package:spotife/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final hasSession = await authService.restoreSessionOnAppLaunch();

  if (kDebugMode) {}
  runApp(SpotifyLikeApp(isAuthenticated: hasSession));
}

class SpotifyLikeApp extends StatelessWidget {
  const SpotifyLikeApp({super.key, required this.isAuthenticated});

  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spotify Login',
      theme: base.copyWith(
        scaffoldBackgroundColor: kBg,
        colorScheme: base.colorScheme.copyWith(
          primary: kSpotifyGreen,
          secondary: kSpotifyGreen,
        ),
        textTheme: GoogleFonts.interTextTheme(
          base.textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
      ),
      initialRoute: isAuthenticated ? AppRoutes.home : AppRoutes.main,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
