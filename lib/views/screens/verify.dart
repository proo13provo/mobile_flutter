import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotife/routes/app_routes.dart';
import 'package:spotife/service/api/auth_service.dart';
import 'package:spotife/service/secure_storage_service.dart';

const kSpotifyGreen = Color(0xFF1DB954);
const kBg = Color(0xFF121212);
const kCard = Color(0xFF1E1E1E);

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({
    super.key,
    this.email, // truyền email để hiển thị
  });

  final String? email;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _formKey = GlobalKey<FormState>();

  // 6 ô mã
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  int _secondsLeft = 30; // đếm ngược resend
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // auto-focus ô đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  String get _code => _controllers.map((e) => e.text).join();
  bool get _canVerify =>
      _code.length == 6 && !_code.contains(RegExp(r'[^0-9]'));

  final _storage = SecureStorageService();
  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!_canVerify || _isVerifying) return;

    setState(() => _isVerifying = true);
    try {
      // Lấy email truyền từ trang register qua arguments
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      final email = args?['email']?.toString() ?? '';
      final verificationCode = _controllers.map((c) => c.text.trim()).join();
      final auth = AuthService();

      if (email.isEmpty || verificationCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email hoặc mã xác minh không hợp lệ')),
        );
        return;
      }

      final result = await auth.verify(
        email: email,
        verificationCode: verificationCode,
      );

      if (!mounted) return;

      final message = result.auth.message;

      if (result.ok) {
        final accessToken = result.auth.accessToken;
        if (accessToken.isNotEmpty) {
          await _storage.saveAccessToken(accessToken);
        }
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi xác minh: $e')));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    // TODO: Gọi API gửi lại mã / Firebase sendEmailVerification()
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Verification code resent')));
    _startTimer();
  }

  InputDecoration _otpDecoration() {
    return InputDecoration(
      counterText: '',
      filled: true,
      fillColor: kCard,
      contentPadding: EdgeInsets.zero,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kSpotifyGreen, width: 1.6),
      ),
    );
  }

  Widget _otpBox(int i) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[i],
        focusNode: _focusNodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        maxLength: 1,
        decoration: _otpDecoration(),
        onChanged: (v) {
          // chỉ nhận số
          if (v.isNotEmpty && !RegExp(r'^[0-9]$').hasMatch(v)) {
            _controllers[i].clear();
            return;
          }
          // tự chuyển focus
          if (v.isNotEmpty) {
            if (i < 5) _focusNodes[i + 1].requestFocus();
          } else {
            if (i > 0) _focusNodes[i - 1].requestFocus();
          }
          setState(() {}); // cập nhật _canVerify
        },
        onSubmitted: (_) {
          if (i == 5 && _canVerify) _verify();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final email = args?['email']?.toString() ?? '';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          },
        ),
        title: const Text('Verify your account'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: kSpotifyGreen,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter the 6-digit code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a code to $email',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),

                    // 6 ô OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, _otpBox),
                    ),

                    const SizedBox(height: 20),

                    // Change email (tuỳ chọn)
                    TextButton(
                      onPressed: () {
                        // TODO: Điều hướng về signup để đổi email, hoặc mở dialog thay đổi email
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Change email tapped')),
                        );
                      },
                      child: const Text('Use a different email'),
                    ),

                    const SizedBox(height: 8),

                    // Resend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Didn’t get the code? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: _secondsLeft == 0 ? _resend : null,
                          child: Text(
                            _secondsLeft == 0
                                ? 'Resend'
                                : 'Resend in $_secondsLeft s',
                            style: TextStyle(
                              color: _secondsLeft == 0
                                  ? Colors.white
                                  : Colors.white54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canVerify
                              ? kSpotifyGreen
                              : Colors.white10,
                          foregroundColor: _canVerify
                              ? Colors.black
                              : Colors.white54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: _canVerify && !_isVerifying ? _verify : null,
                        child: _isVerifying
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                ),
                              )
                            : const Text('Verify'),
                      ),
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
