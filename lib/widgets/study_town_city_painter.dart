part of 'study_town_scene.dart';

extension _StudyTownCityPainter on _StudyTownPainter {
  // Paints the blue midnight coding desk inspired by city-window photos.
  void _paintMidnightCity(Canvas canvas, Size size) {
    _paintNightWindow(canvas, size);
    _paintSkyline(canvas, size);
    _paintGlassRail(canvas, size);
    _paintDeskSurface(canvas, size, theme.surface.withValues(alpha: 0.90));
    _paintMonitor(
      canvas,
      Offset(size.width * 0.56, size.height * 0.44),
      size.width * 0.32,
    );
    _paintLaptop(
      canvas,
      Offset(size.width * 0.30, size.height * 0.54),
      size.width * 0.27,
      dark: true,
    );
    _paintKeyboard(
      canvas,
      Offset(size.width * 0.60, size.height * 0.61),
      size.width * 0.22,
    );
    _paintToyCar(canvas, Offset(size.width * 0.17, size.height * 0.62), 0.8);
    _paintCup(
      canvas,
      Offset(size.width * 0.75, size.height * 0.58),
      14,
      theme.accent,
    );
  }

  // Paints a full-height night window for city scenes.
  void _paintNightWindow(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A1620),
    );
    final glass = Paint()
      ..color = const Color(0xFF18364A).withValues(alpha: 0.55);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.05,
        size.width * 0.92,
        size.height * 0.56,
      ),
      glass,
    );
    final frame = Paint()
      ..color = const Color(0xFF081018)
      ..strokeWidth = 5;
    for (final x in [0.28, 0.52, 0.76]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * 0.05),
        Offset(size.width * x, size.height * 0.61),
        frame,
      );
    }
  }

  // Paints simplified high-rise buildings and lit windows.
  void _paintSkyline(Canvas canvas, Size size) {
    final buildings = [
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.28,
        size.width * 0.13,
        size.height * 0.32,
      ),
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.16,
        size.width * 0.16,
        size.height * 0.44,
      ),
      Rect.fromLTWH(
        size.width * 0.42,
        size.height * 0.33,
        size.width * 0.17,
        size.height * 0.27,
      ),
      Rect.fromLTWH(
        size.width * 0.64,
        size.height * 0.22,
        size.width * 0.14,
        size.height * 0.38,
      ),
      Rect.fromLTWH(
        size.width * 0.80,
        size.height * 0.31,
        size.width * 0.11,
        size.height * 0.29,
      ),
    ];
    for (final building in buildings) {
      canvas.drawRect(building, Paint()..color = const Color(0xFF1E2B36));
      _paintBuildingWindows(canvas, building);
    }
  }

  // Paints lit windows inside a single building block.
  void _paintBuildingWindows(Canvas canvas, Rect building) {
    for (var x = building.left + 8; x < building.right - 4; x += 14) {
      for (var y = building.top + 10; y < building.bottom - 6; y += 16) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, 5, 5),
          Paint()
            ..color = theme.accent.withValues(
              alpha: (x + y).round().isEven ? 0.7 : 0.25,
            ),
        );
      }
    }
  }

  // Paints a balcony glass rail in front of the city.
  void _paintGlassRail(Canvas canvas, Size size) {
    final rail = Rect.fromLTWH(
      0,
      size.height * 0.55,
      size.width,
      size.height * 0.12,
    );
    canvas.drawRect(
      rail,
      Paint()..color = const Color(0xFF8EC5D1).withValues(alpha: 0.20),
    );
    canvas.drawLine(
      Offset(0, rail.top),
      Offset(size.width, rail.top),
      Paint()
        ..color = const Color(0xFFB7E6EF).withValues(alpha: 0.35)
        ..strokeWidth = 3,
    );
  }

  // Paints a monitor with rows of code.
  void _paintMonitor(Canvas canvas, Offset center, double width) {
    final screen = Rect.fromCenter(
      center: center,
      width: width,
      height: width * 0.56,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(screen.inflate(8), const Radius.circular(8)),
      Paint()..color = const Color(0xFF10151C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(screen, const Radius.circular(4)),
      Paint()..color = const Color(0xFF202733),
    );
    _paintCodeLines(canvas, screen.deflate(12), 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, screen.height * 0.60),
          width: width * 0.30,
          height: 10,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF343A42),
    );
  }

  // Paints a simple keyboard on a desk.
  void _paintKeyboard(Canvas canvas, Offset center, double width) {
    final rect = Rect.fromCenter(
      center: center,
      width: width,
      height: width * 0.22,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF1E242C),
    );
    for (var row = 0; row < 3; row++) {
      for (var key = 0; key < 8; key++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.left + 8 + key * 12,
              rect.top + 6 + row * 9,
              8,
              5,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF59616B),
        );
      }
    }
  }

  // Paints a tiny desk toy car.
  void _paintToyCar(Canvas canvas, Offset center, double scale) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 48 * scale, height: 18 * scale),
        const Radius.circular(8),
      ),
      Paint()..color = theme.accent,
    );
    canvas.drawCircle(
      center.translate(-14 * scale, 10 * scale),
      5 * scale,
      Paint()..color = const Color(0xFF151515),
    );
    canvas.drawCircle(
      center.translate(14 * scale, 10 * scale),
      5 * scale,
      Paint()..color = const Color(0xFF151515),
    );
  }
}
