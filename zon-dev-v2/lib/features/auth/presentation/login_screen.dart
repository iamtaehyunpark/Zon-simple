import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Custom URL scheme registered in ios/Runner/Info.plist. The native auth
  // session intercepts redirects to this scheme and hands the callback back.
  static const _callbackScheme = 'app.getzon';
  static const _redirectUrl = '$_callbackScheme://login-callback';

  bool _loading = false;
  String? _error;

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    setState(() { _loading = true; _error = null; });
    final auth = Supabase.instance.client.auth;
    try {
      // 1. Build the provider's authorization URL (this also stores the PKCE
      //    verifier that the exchange in step 3 needs).
      final res = await auth.getOAuthSignInUrl(
        provider: provider,
        redirectTo: _redirectUrl,
      );

      // 2. Present it in a native in-app auth session (ASWebAuthenticationSession
      //    on iOS). It dismisses itself the instant the callback scheme fires and
      //    returns the callback URL — no external Safari, no stuck sheet.
      final callback = await FlutterWebAuth2.authenticate(
        url: res.url,
        callbackUrlScheme: _callbackScheme,
      );

      // 3. Exchange the returned code for a session. onAuthStateChange then
      //    fires signedIn → GoRouter redirects to /feed and disposes this
      //    screen, so the spinner naturally goes away.
      await auth.getSessionFromUrl(Uri.parse(callback));
    } on PlatformException catch (e) {
      // The user dismissed the auth sheet — not an error, just stop spinning.
      if (mounted) {
        setState(() {
          _loading = false;
          if (e.code != 'CANCELED') _error = e.message ?? e.code;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text(
                'ZON',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: kBrandGreen,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your place-based diary',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const Spacer(flex: 3),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              _AuthButton(
                label: 'Continue with Apple',
                icon: Icons.apple,
                onTap: _loading
                    ? null
                    : () => _signInWithOAuth(OAuthProvider.apple),
                dark: true,
              ),
              const SizedBox(height: 12),
              _AuthButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                onTap: _loading
                    ? null
                    : () => _signInWithOAuth(OAuthProvider.google),
                dark: false,
              ),
              if (_loading) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: kBrandGreen),
              ],
              const Spacer(),
              const Text(
                'By continuing, you agree to our Terms & Privacy Policy',
                style: TextStyle(color: Colors.white24, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: dark ? Colors.black : Colors.white,
          foregroundColor: dark ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
