import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/auth/auth_service.dart';

/// Entry point for unauthenticated users.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn(Future<void> Function() action) async {
    setState(() { _loading = true; _error = null; });
    try {
      await action();
      // Password auth: currentUser is set immediately — navigate now.
      // OAuth: action() returns before auth completes (browser flow) —
      //   GoRouter's onAuthStateChange listener handles navigation on deep-link return.
      if (mounted && Supabase.instance.client.auth.currentUser != null) {
        context.go('/feed');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _ZonLogo(),
              const SizedBox(height: 16),
              const Text(
                'Prove you were there.',
                style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 0.3),
              ),
              const Spacer(flex: 3),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],
              if (_loading)
                const CircularProgressIndicator(color: Color(0xFF1D9E75))
              else
                Column(
                  children: [
                    _SocialButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata_rounded,
                      onTap: () => _signIn(AuthService.signInWithGoogle),
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      borderColor: const Color(0xFF333333),
                    ),
                    if (!kReleaseMode) ...[
                      const SizedBox(height: 12),
                      _SocialButton(
                        label: 'Test Account Login',
                        icon: Icons.bug_report_outlined,
                        onTap: () => _signIn(AuthService.signInWithTestAccount),
                        backgroundColor: const Color(0xFF1A1200),
                        foregroundColor: const Color(0xFFFFCC00),
                        borderColor: const Color(0xFF665500),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 24),
              Text(
                'By continuing you agree to ZON\'s Terms of Service\nand Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZonLogo extends StatelessWidget {
  const _ZonLogo();

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF1D9E75),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text('Z',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                )),
          ),
        ),
        const SizedBox(height: 16),
        const Text('ZON',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            )),
      ]);
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            side: BorderSide(color: borderColor ?? backgroundColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(icon, size: 22),
          label: Text(label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      );
}
