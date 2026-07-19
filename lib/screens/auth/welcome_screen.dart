import 'package:flutter/material.dart';

import '../../app/study_nest_state.dart';
import '../../app/study_nest_scope.dart';
import 'auth_widgets.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.onDismiss});

  final VoidCallback? onDismiss;

  // Creates the mutable state used for Google sign-in progress.
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _loadingGoogle = false;
  String? _error;

  // Links the current local phone data to Google and closes the auth flow.
  Future<void> _continueWithGoogle() async {
    setState(() {
      _loadingGoogle = true;
      _error = null;
    });
    final result = await StudyNestScope.read(
      context,
    ).linkAnonymousAccountWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _loadingGoogle = false);
    if (result.applied) {
      _finishEntry();
    } else {
      setState(() => _error = result.message);
    }
  }

  // Builds the adaptive first-use entry screen for signing in or continuing.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.background,
              Color.alphaBlend(
                theme.primary.withValues(alpha: 0.12),
                theme.background,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.03),
                      // Logo / Illustration
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text('🪺', style: TextStyle(fontSize: 48)),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'StudyNest',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.primary,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your cozy study companion.\nTasks, notes, focus — all in one place.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.muted,
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      GoogleAuthButton(
                        loading: _loadingGoogle,
                        onPressed: _continueWithGoogle,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        AuthErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 14),
                      // Sign Up button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _pushRegister(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: theme.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Create Account'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Sign In button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => _pushLogin(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primary,
                            side: BorderSide(
                              color: theme.primary.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (widget.onDismiss != null)
                        TextButton(
                          onPressed: _finishEntry,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.muted,
                          ),
                          child: const Text('Continue without an account'),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pushLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen(onSuccess: _finishEntry)),
    );
  }

  // Closes every nested auth route before returning to the active app shell.
  void _finishEntry() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onDismiss?.call();
  }

  // Opens registration while preserving the parent welcome completion callback.
  void _pushRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(onSuccess: _finishEntry),
      ),
    );
  }
}
