import 'package:flutter/material.dart';

import '../../app/study_nest_scope.dart';

// Reusable "Sign in with Google" button used across Welcome, Login and Register.
// Calls StudyNestState.signInWithGoogle() and reports result via callbacks.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onSuccess,
    this.onError,
    this.label = 'Continue with Google',
  });

  final VoidCallback onSuccess;
  final ValueChanged<String>? onError;
  final String label;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _loading = false;

  // Triggers the Google sign-in flow and forwards the result to callbacks.
  Future<void> _signIn() async {
    setState(() => _loading = true);
    final state = StudyNestScope.read(context);
    final result = await state.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.applied) {
      widget.onSuccess();
    } else {
      widget.onError?.call(result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _loading ? null : _signIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF3C4043),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo painted manually — no image asset needed.
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C4043),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Paints the Google "G" logo using the four official brand colours.
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Draw coloured arc segments of the G circle.
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    // Blue — top-right to bottom-right (roughly 300° span split into 3 parts).
    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.82),
      -0.28, // start ~-16°
      3.73,  // sweep ~214°
      false,
      arcPaint,
    );

    // Green — bottom
    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.82),
      3.45,
      1.05,
      false,
      arcPaint,
    );

    // Yellow — bottom-left
    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.82),
      4.50,
      0.70,
      false,
      arcPaint,
    );

    // Red — left to top
    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.82),
      5.20,
      1.36,
      false,
      arcPaint,
    );

    // Draw the horizontal crossbar of the "G".
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.82, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
