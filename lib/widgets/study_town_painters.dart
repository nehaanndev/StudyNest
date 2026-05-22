part of 'study_town_scene.dart';

class _StudyTownPainter extends CustomPainter {
  const _StudyTownPainter({
    required this.theme,
    required this.isComplete,
    required this.styleId,
  });

  final StudyVisualTheme theme;
  final bool isComplete;
  final String styleId;

  // Paints the selected study room scene for the active theme.
  @override
  void paint(Canvas canvas, Size size) {
    _paintBaseWash(canvas, size);
    if (styleId == 'simple') {
      _paintSimpleStudyRoom(canvas, size);
    } else {
      switch (theme.id) {
        case 'rainyLibrary':
          _paintRainyLibrary(canvas, size);
        case 'midnightCity':
          _paintMidnightCity(canvas, size);
        case 'gardenMatcha':
          _paintGardenMatcha(canvas, size);
        default:
          _paintCafeBookstore(canvas, size);
      }
      if (styleId == 'detail') {
        _paintDetailRoomFinish(canvas, size);
      }
    }
    if (isComplete) {
      _paintCompletionGlow(canvas, size);
    }
  }

  // Reports whether the scene should repaint after theme or status changes.
  @override
  bool shouldRepaint(covariant _StudyTownPainter oldDelegate) {
    return oldDelegate.theme != theme ||
        oldDelegate.isComplete != isComplete ||
        oldDelegate.styleId != styleId;
  }

  // Paints the base wash used behind every room variant.
  void _paintBaseWash(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(theme.accent.withValues(alpha: 0.18), theme.surface),
          theme.surfaceAlt,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  // Paints a calmer room variant for users who prefer simpler study spaces.
  void _paintSimpleStudyRoom(Canvas canvas, Size size) {
    switch (theme.id) {
      case 'rainyLibrary':
        _paintSimpleRainyLibrary(canvas, size);
      case 'midnightCity':
        _paintSimpleMidnightCity(canvas, size);
      case 'gardenMatcha':
        _paintSimpleGardenMatcha(canvas, size);
      default:
        _paintSimpleCafeBookstore(canvas, size);
    }
  }

  // Paints a simple theme-colored room window.
  void _paintSimpleWindow(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(5), const Radius.circular(9)),
      Paint()..color = theme.primary.withValues(alpha: 0.50),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = theme.id == 'midnightCity'
            ? const Color(0xFF18364A)
            : const Color(0xFFCFE0E0),
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top),
      Offset(rect.center.dx, rect.bottom),
      Paint()
        ..color = theme.primary.withValues(alpha: 0.45)
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      Paint()
        ..color = theme.primary.withValues(alpha: 0.45)
        ..strokeWidth = 3,
    );
  }

  // Paints a small pastry plate for applied cafe decor.
  void _paintPastryTray(Canvas canvas, Size size) {
    final tray = Rect.fromCenter(
      center: Offset(size.width * 0.30, size.height * 0.71),
      width: 86,
      height: 28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tray, const Radius.circular(14)),
      Paint()..color = const Color(0xFFE8D7BE),
    );
    for (var index = 0; index < 3; index++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tray.left + 24 + index * 22, tray.center.dy),
          width: 20,
          height: 12,
        ),
        Paint()..color = const Color(0xFFD69A50),
      );
    }
  }

  // Paints a green reading chair for applied library decor.
  void _paintVelvetChair(Canvas canvas, Offset center) {
    final paint = Paint()..color = theme.secondary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 58, height: 42),
        const Radius.circular(12),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 26), width: 70, height: 22),
        const Radius.circular(10),
      ),
      paint,
    );
  }

  // Paints a bright skyline sign for applied city decor.
  void _paintNeonSign(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.68,
      size.height * 0.16,
      size.width * 0.20,
      size.height * 0.08,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF10151C),
    );
    canvas.drawLine(
      rect.centerLeft.translate(12, 0),
      rect.centerRight.translate(-12, 0),
      Paint()
        ..color = theme.accent.withValues(alpha: 0.92)
        ..strokeWidth = 4,
    );
  }

  // Paints a warm hanging lamp.
  void _paintPendantLamp(Canvas canvas, Offset top, double width) {
    final cord = Paint()
      ..color = const Color(0xFF3B2B23)
      ..strokeWidth = 2;
    canvas.drawLine(top, top.translate(0, 42), cord);
    final shade = Path()
      ..moveTo(top.dx - width / 2, top.dy + 64)
      ..lineTo(top.dx - width * 0.30, top.dy + 42)
      ..lineTo(top.dx + width * 0.30, top.dy + 42)
      ..lineTo(top.dx + width / 2, top.dy + 64)
      ..close();
    canvas.drawPath(shade, Paint()..color = const Color(0xFFC58B4C));
    canvas.drawOval(
      Rect.fromCenter(center: top.translate(0, 64), width: width, height: 13),
      Paint()..color = theme.accent.withValues(alpha: 0.55),
    );
  }

  // Paints a foreground desk surface for desk-heavy scenes.
  void _paintDeskSurface(Canvas canvas, Size size, Color color) {
    final desk = Path()
      ..moveTo(0, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.56)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(desk, Paint()..color = color);
  }

  // Paints a laptop with a dark screen and keyboard.
  void _paintLaptop(
    Canvas canvas,
    Offset center,
    double width, {
    required bool dark,
  }) {
    final screen = Rect.fromCenter(
      center: center,
      width: width,
      height: width * 0.58,
    );
    final screenPaint = Paint()
      ..color = dark ? const Color(0xFF15191F) : theme.surface;
    canvas.drawRRect(
      RRect.fromRectAndRadius(screen, const Radius.circular(6)),
      screenPaint,
    );
    _paintCodeLines(canvas, screen.deflate(9), 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          screen.left - 8,
          screen.bottom - 2,
          screen.width + 16,
          screen.height * 0.34,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF30333A),
    );
  }

  // Paints rows of code-like strokes inside a screen.
  void _paintCodeLines(Canvas canvas, Rect rect, int count) {
    final colors = [theme.accent, theme.secondary, const Color(0xFFCBD5E1)];
    for (var index = 0; index < count; index++) {
      final y = rect.top + 4 + index * rect.height / count;
      final width = rect.width * (0.35 + (index % 4) * 0.13);
      canvas.drawLine(
        Offset(rect.left + (index % 3) * 8, y),
        Offset(rect.left + width, y),
        Paint()
          ..color = colors[index % colors.length].withValues(alpha: 0.9)
          ..strokeWidth = 2,
      );
    }
  }

  // Paints a mug or cafe cup.
  void _paintCup(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: radius * 1.8,
          height: radius * 1.5,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = color,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, -radius * 0.68),
        width: radius * 1.8,
        height: radius * 0.55,
      ),
      Paint()..color = const Color(0xFFF4E4C6),
    );
  }

  // Paints a potted plant with rounded leaves.
  void _paintPottedPlant(Canvas canvas, Offset base, double scale) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base, width: 28 * scale, height: 24 * scale),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF8A5739),
    );
    for (final dx in [-12.0, 0.0, 12.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: base.translate(dx * scale, -28 * scale),
          width: 17 * scale,
          height: 34 * scale,
        ),
        Paint()..color = theme.secondary,
      );
    }
  }

  // Paints celebratory light shapes when the daily focus goal is complete.
  void _paintCompletionGlow(Canvas canvas, Size size) {
    final glowPaint = Paint()..color = theme.accent.withValues(alpha: 0.55);
    for (final point in [
      Offset(size.width * 0.30, size.height * 0.22),
      Offset(size.width * 0.66, size.height * 0.32),
      Offset(size.width * 0.53, size.height * 0.14),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(point.dx, point.dy - 8)
          ..lineTo(point.dx + 5, point.dy)
          ..lineTo(point.dx, point.dy + 8)
          ..lineTo(point.dx - 5, point.dy)
          ..close(),
        glowPaint,
      );
    }
  }
}
