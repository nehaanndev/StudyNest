part of 'study_town_scene.dart';

extension _StudyTownMatchaPainter on _StudyTownPainter {
  // Paints the matcha cafe laptop scene inspired by quiet Starbucks tables.
  void _paintGardenMatcha(Canvas canvas, Size size) {
    _paintGlassCafeWall(canvas, size);
    _paintCafeBooths(canvas, size);
    _paintDeskSurface(canvas, size, const Color(0xFFB78250));
    _paintLaptop(
      canvas,
      Offset(size.width * 0.62, size.height * 0.54),
      size.width * 0.36,
      dark: true,
    );
    _paintNotebook(
      canvas,
      Offset(size.width * 0.33, size.height * 0.59),
      size.width * 0.26,
    );
    _paintMatchaCup(canvas, Offset(size.width * 0.39, size.height * 0.48), 25);
    _paintWirelessBuds(
      canvas,
      Offset(size.width * 0.27, size.height * 0.62),
      1.0,
    );
    _paintPottedPlant(
      canvas,
      Offset(size.width * 0.13, size.height * 0.40),
      0.9,
    );
    _paintPottedPlant(
      canvas,
      Offset(size.width * 0.87, size.height * 0.38),
      0.8,
    );
  }

  // Paints a glass coffee-shop wall with interior silhouettes.
  void _paintGlassCafeWall(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1A2B24),
    );
    final pane = Paint()
      ..color = const Color(0xFF324D45).withValues(alpha: 0.68);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.03,
        size.height * 0.06,
        size.width * 0.94,
        size.height * 0.52,
      ),
      pane,
    );
    final frame = Paint()
      ..color = const Color(0xFF0E1714)
      ..strokeWidth = 5;
    for (final x in [0.22, 0.44, 0.66, 0.86]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * 0.06),
        Offset(size.width * x, size.height * 0.58),
        frame,
      );
    }
    canvas.drawLine(
      Offset(size.width * 0.03, size.height * 0.32),
      Offset(size.width * 0.97, size.height * 0.32),
      frame,
    );
  }

  // Paints muted booth silhouettes behind the glass wall.
  void _paintCafeBooths(Canvas canvas, Size size) {
    final boothPaint = Paint()
      ..color = const Color(0xFF0B0E0D).withValues(alpha: 0.72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.13,
          size.height * 0.38,
          size.width * 0.18,
          size.height * 0.12,
        ),
        const Radius.circular(10),
      ),
      boothPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.68,
          size.height * 0.36,
          size.width * 0.18,
          size.height * 0.13,
        ),
        const Radius.circular(10),
      ),
      boothPaint,
    );
    _paintPendantLamp(
      canvas,
      Offset(size.width * 0.50, size.height * 0.03),
      30,
    );
  }

  // Paints a notebook with page lines.
  void _paintNotebook(Canvas canvas, Offset center, double width) {
    final rect = Rect.fromCenter(
      center: center,
      width: width,
      height: width * 0.45,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = const Color(0xFFE9D8B8),
    );
    for (var index = 0; index < 5; index++) {
      final y = rect.top + 12 + index * 10;
      canvas.drawLine(
        Offset(rect.left + 12, y),
        Offset(rect.right - 12, y),
        Paint()
          ..color = const Color(0xFF8C7A60).withValues(alpha: 0.45)
          ..strokeWidth = 1.4,
      );
    }
  }

  // Paints a glass matcha latte cup.
  void _paintMatchaCup(Canvas canvas, Offset center, double radius) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2.1,
        height: radius * 0.82,
      ),
      Paint()..color = const Color(0xFFEDE8DB),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, -2),
        width: radius * 1.7,
        height: radius * 0.56,
      ),
      Paint()..color = const Color(0xFFAEC987),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, radius * 0.72),
          width: radius * 1.65,
          height: radius * 1.25,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFB9D69A).withValues(alpha: 0.72),
    );
  }

  // Paints a wireless earbud case and buds.
  void _paintWirelessBuds(Canvas canvas, Offset center, double scale) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 32 * scale, height: 22 * scale),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFF6F1E5),
    );
    canvas.drawCircle(
      center.translate(28 * scale, -8 * scale),
      5 * scale,
      Paint()..color = const Color(0xFFF6F1E5),
    );
    canvas.drawCircle(
      center.translate(39 * scale, -5 * scale),
      4 * scale,
      Paint()..color = const Color(0xFFF6F1E5),
    );
  }
}
