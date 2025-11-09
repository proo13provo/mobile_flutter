import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spotife/routes/app_routes.dart';
import 'package:spotife/service/api/auth_service.dart';
import 'package:spotife/service/google_sign_in_service.dart';
import 'package:spotife/theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _authService = AuthService();
  final _googleSignIn = GoogleSignInService();
  bool _isGoogleLoading = false;

  Future<void> _onGooglePressed() async {
    if (_isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      final credentials = await _googleSignIn.requestCredentials();
      if (!mounted) return;

      if (credentials == null || !credentials.hasCredential) {
        _showSnack(context, 'Google Sign-In was cancelled');
        return;
      }

      final code = credentials.serverAuthCode;
      if (code == null || code.isEmpty) {
        _showSnack(context, 'Unable to get Google authorization code.');
        return;
      }

      final result = await _authService.loginWithGoogle(code: code);
      if (!mounted) return;

      if (result.ok) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        _showSnack(context, result.auth.message);
      }
    } on StateError catch (e) {
      if (!mounted) return;
      _showSnack(context, e.message);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message =
          (e.message != null && e.message!.isNotEmpty)
              ? e.message!
              : 'Google Sign-In failed (${e.code})';
      debugPrint('Google Sign-In PlatformException: $e');
      _showSnack(context, message);
    } catch (error) {
      if (!mounted) return;
      debugPrint('Google Sign-In unexpected error: $error');
      _showSnack(
        context,
        'Unable to complete Google Sign-In. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 480;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 20,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  _Wordmark(),
                  const SizedBox(height: 8),
                  Text(
                    'Millions of songs. Free on Spotify.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _PrimaryButton(
                    text: 'Sign up free',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.signup);
                    },
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    icon: FontAwesomeIcons.google,
                    label: 'Continue with Google',
                    isLoading: _isGoogleLoading,
                    onTap: _onGooglePressed,
                  ),
                  const SizedBox(height: 10),
                  _SocialButton(
                    icon: FontAwesomeIcons.facebookF,
                    label: 'Continue with Facebook',
                    onTap: () {
                      _showSnack(context, 'Facebook Login tapped');
                    },
                  ),
                  const SizedBox(height: 10),
                  _SocialButton(
                    icon: FontAwesomeIcons.apple,
                    label: 'Continue with Apple',
                    onTap: () {
                      _showSnack(context, 'Apple Sign-In tapped');
                    },
                  ),
                  const SizedBox(height: 10),
                  _SocialButton(
                    iconData: Icons.phone_rounded,
                    label: 'Continue with phone number',
                    onTap: () {
                      _showSnack(context, 'Phone flow tapped');
                    },
                  ),
                  const SizedBox(height: 18),
                  _OrDivider(),
                  const SizedBox(height: 10),
                  _OutlineButton(
                    text: 'Log in',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                  ),
                  const SizedBox(height: 18),
                  _LegalText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FaIcon(
          FontAwesomeIcons.spotify,
          color: Color(0xFF1DB954),
          size: 72,
        ),
        const SizedBox(height: 12),
        Text(
          'Spotify',
          style: GoogleFonts.inter(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kSpotifyGreen,
          foregroundColor: Colors.black,
          elevation: 4,
          shadowColor: kSpotifyGreen.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _OutlineButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          backgroundColor: kCard.withValues(alpha: 0.3),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? iconData;
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _SocialButton({
    this.iconData,
    this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  }) : assert(iconData != null || icon != null, 'Provide an icon');

  @override
  Widget build(BuildContext context) {
    final iconWidget = iconData != null
        ? Icon(iconData, size: 20, color: Colors.white)
        : FaIcon(icon, size: 20, color: Colors.white);

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              iconWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.28);
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('or', style: TextStyle(color: Colors.white70)),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}

class _LegalText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.9),
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 12.5,
          height: 1.4,
        ),
        children: [
          const TextSpan(text: 'By continuing, you agree to the '),
          TextSpan(text: 'Terms of Service', style: linkStyle),
          const TextSpan(text: ' and acknowledge the '),
          TextSpan(text: 'Privacy Policy', style: linkStyle),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2A2A2A),
    ),
  );
}
