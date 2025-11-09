import 'package:google_sign_in/google_sign_in.dart';

import 'package:spotife/core/constants/api_constants.dart';

class GoogleSignInResult {
  const GoogleSignInResult({
    required this.serverAuthCode,
    required this.idToken,
    required this.accessToken,
  });

  final String? serverAuthCode;
  final String? idToken;
  final String? accessToken;

  bool get hasCredential =>
      (serverAuthCode != null && serverAuthCode!.isNotEmpty) ||
      (idToken != null && idToken!.isNotEmpty);
}

/// Handles the native Google Sign-In flow and surfaces the credentials
/// expected by the backend.
class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: _defaultScopes,
            serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
          );

  static const List<String> _defaultScopes = <String>['email', 'profile'];
  static final String _serverClientId = _resolveClientId();

  static String _resolveClientId() {
    const envClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '',
    );
    if (envClientId.isNotEmpty) {
      return envClientId;
    }
    return ApiConstants.clientId;
  }

  final GoogleSignIn _googleSignIn;

  /// Requests Google credentials (server auth code + ID token) that can be
  /// exchanged by the backend. Returns `null` if the user cancels.
  Future<GoogleSignInResult?> requestCredentials() async {
    if (_serverClientId.isEmpty) {
      throw StateError(
        'Missing Google OAuth client ID. Update ApiConstants.clientId or provide --dart-define=GOOGLE_SERVER_CLIENT_ID.',
      );
    }

    GoogleSignInAccount? account = await _signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }

    var result = await _extractCredentials(account);
    if (result.hasCredential) {
      return result;
    }

    await _googleSignIn.disconnect();
    account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }

    result = await _extractCredentials(account);
    return result.hasCredential ? result : null;
  }

  Future<GoogleSignInAccount?> _signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  Future<GoogleSignInResult> _extractCredentials(
    GoogleSignInAccount account,
  ) async {
    final auth = await account.authentication;
    final code = account.serverAuthCode;
    return GoogleSignInResult(
      serverAuthCode: (code != null && code.isNotEmpty) ? code : null,
      idToken: (auth.idToken != null && auth.idToken!.isNotEmpty)
          ? auth.idToken
          : null,
      accessToken: (auth.accessToken != null && auth.accessToken!.isNotEmpty)
          ? auth.accessToken
          : null,
    );
  }
}
