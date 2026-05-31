import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_visuals.dart';

const _quotes = [
  'Focus on the progress, not the perfection.',
  'One session at a time.',
  'Stay consistent, results will follow.',
  'Small steps every day.',
  'Deep work is a superpower.',
];

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const _focusMinutes = 25;
  static const _breakMinutes = 5;

  int _cyclesCompleted = 0;
  bool _isRunning = false;
  bool _isBreak = false;
  int _secondsLeft = _focusMinutes * 60;
  Timer? _timer;
  int _quoteIndex = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStop() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          _advance();
        }
      });
    }
  }

  void _advance() {
    _timer?.cancel();
    setState(() {
      if (!_isBreak) {
        _cyclesCompleted++;
        _isBreak = true;
        _secondsLeft = _breakMinutes * 60;
        _quoteIndex = (_quoteIndex + 1) % _quotes.length;
      } else {
        _isBreak = false;
        _secondsLeft = _focusMinutes * 60;
      }
      _isRunning = false;
    });
  }

  String get _formatted {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = _isBreak ? _breakMinutes * 60 : _focusMinutes * 60;
    return (_secondsLeft / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final visuals = visualsForTheme(state.selectedTheme.id);
    final ringColor = _isBreak ? const Color(0xFF7ACC7A) : theme.accent;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen room background ──────────────────────────────
          Image.asset(
            visuals.detailImagePath,
            fit: BoxFit.cover,
          ),
          // Dark overlay to make content readable
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),

          // ── Scrollable content over the room ────────────────────────
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pomodoro',
                            style: TextStyle(
                              color: theme.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                            ),
                          ),
                          Text(
                            _isBreak ? 'Break time — relax a little' : 'Deep work in focused sprints',
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quote glass card
                _GlassCard(
                  child: Row(
                    children: [
                      Icon(Icons.format_quote_rounded,
                          color: theme.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _quotes[_quoteIndex],
                          style: TextStyle(
                            color: theme.text,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // ── Giant circular timer ─────────────────────────────
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ringColor.withValues(alpha: 0.25),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        // Progress arc
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            color: ringColor,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        // Glass inner circle
                        ClipOval(
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                color: theme.surface
                                    .withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      ringColor.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatted,
                                    style: TextStyle(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      color: theme.text,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: ringColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isBreak
                                            ? 'Break Time'
                                            : 'Focus Time',
                                        style: TextStyle(
                                          color: ringColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Stats row
                Row(
                  children: [
                    _StatPill(
                      value: '$_focusMinutes min',
                      label: 'Focus',
                      color: theme.accent,
                    ),
                    _StatPill(
                      value: '$_breakMinutes min',
                      label: 'Break',
                      color: const Color(0xFF7ACC7A),
                    ),
                    _StatPill(
                      value: '$_cyclesCompleted',
                      label: 'Cycles',
                      color: theme.text,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: Icons.notifications_off_outlined,
                      theme: theme,
                      onPressed: () {},
                      size: 52,
                    ),
                    const SizedBox(width: 20),
                    // Big play/pause
                    GestureDetector(
                      onTap: _startStop,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.accent.withValues(alpha: 0.20),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.accent.withValues(alpha: 0.70),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      theme.accent.withValues(alpha: 0.30),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRunning ? Icons.pause : Icons.play_arrow,
                              size: 40,
                              color: theme.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    _ControlButton(
                      icon: Icons.skip_next_outlined,
                      theme: theme,
                      onPressed: _advance,
                      size: 52,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Bottom tip card
                _GlassCard(
                  child: Row(
                    children: [
                      Icon(Icons.savings_outlined,
                          color: theme.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Stay consistent, results will follow.',
                          style: TextStyle(
                              color: theme.text, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared glass card ─────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.20),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Control button ────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.theme,
    required this.onPressed,
    required this.size,
  });
  final IconData icon;
  final dynamic theme;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.22),
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: theme.accent, size: size * 0.44),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}
