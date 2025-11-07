import 'package:flutter/material.dart';
import 'package:spotife/views/screens/home.dart';
import 'package:spotife/views/screens/login.dart';
import 'package:spotife/views/screens/main_screen.dart';
import 'package:spotife/views/screens/signup.dart';
import 'package:spotife/views/screens/verify.dart';

class AppRoutes {
  static const String main = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String verify = '/verify';
  static const String signup = '/signup';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const SpotifyScreen());

      case verify:
        return MaterialPageRoute(builder: (_) => const VerifyScreen());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('404 - Page Not Found'))),
        );
    }
  }
}
