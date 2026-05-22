part of 'study_town_scene.dart';

extension _StudyTownReferenceDetails on _StudyTownPainter {
  // Adds denser detail-room finishes on top of the themed room base.
  void _paintDetailRoomFinish(Canvas canvas, Size size) {
    _paintRoomAtmosphere(canvas, size);
    switch (theme.id) {
      case 'rainyLibrary':
        _paintLibraryReferenceDetails(canvas, size);
      case 'midnightCity':
        _paintCityReferenceDetails(canvas, size);
      case 'gardenMatcha':
        _paintMatchaReferenceDetails(canvas, size);
      default:
        _paintCafeReferenceDetails(canvas, size);
    }
  }

  // Paints layered light falloff and a subtle floor vignette for detail mode.
  void _paintRoomAtmosphere(Canvas canvas, Size size) {
    final glowRect = Offset.zero & size;
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.45),
          radius: 1.08,
          colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent],
        ).createShader(glowRect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.86),
        width: size.width * 0.82,
        height: size.height * 0.22,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.06),
    );
  }

  // Paints extra cafe shelves, menu marks, table objects, and window rain.
  void _paintCafeReferenceDetails(Canvas canvas, Size size) {
    _paintStringLights(canvas, size, size.height * 0.13);
    _paintSmallTableSet(canvas, Offset(size.width * 0.76, size.height * 0.70));
    _paintSmallTableSet(canvas, Offset(size.width * 0.22, size.height * 0.82));
    _paintPastryTray(canvas, size);
    _paintMenuScribbles(
      canvas,
      Rect.fromLTWH(
        size.width * 0.41,
        size.height * 0.10,
        size.width * 0.40,
        size.height * 0.16,
      ),
    );
    _paintWindowStreaks(
      canvas,
      Rect.fromLTWH(
        size.width * 0.09,
        size.height * 0.13,
        size.width * 0.23,
        size.height * 0.29,
      ),
    );
  }

  // Paints extra library ornament, carpet pattern, and table clutter.
  void _paintLibraryReferenceDetails(Canvas canvas, Size size) {
    _paintCeilingRings(canvas, size);
    _paintPatternedRug(
      canvas,
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.70,
        size.width * 0.64,
        size.height * 0.20,
      ),
    );
    _paintBookStack(
      canvas,
      Offset(size.width * 0.37, size.height * 0.61),
      0.62,
    );
    _paintBookStack(
      canvas,
      Offset(size.width * 0.64, size.height * 0.59),
      0.58,
    );
    _paintVelvetChair(canvas, Offset(size.width * 0.81, size.height * 0.73));
    _paintWindowStreaks(
      canvas,
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.14,
        size.width * 0.30,
        size.height * 0.24,
      ),
    );
  }

  // Paints extra skyline lights, reflections, and work-desk objects.
  void _paintCityReferenceDetails(Canvas canvas, Size size) {
    _paintCityTraffic(canvas, size);
    _paintReflectionStreaks(canvas, size);
    _paintNeonSign(canvas, size);
    _paintMonitor(
      canvas,
      Offset(size.width * 0.73, size.height * 0.42),
      size.width * 0.22,
    );
    _paintCodeLines(
      canvas,
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.46,
        size.width * 0.16,
        size.height * 0.06,
      ),
      5,
    );
  }

  // Paints extra glass seams, booth lighting, chair silhouettes, and tableware.
  void _paintMatchaReferenceDetails(Canvas canvas, Size size) {
    _paintStringLights(canvas, size, size.height * 0.09);
    _paintCafeChair(canvas, Offset(size.width * 0.20, size.height * 0.70), 0.8);
    _paintCafeChair(
      canvas,
      Offset(size.width * 0.78, size.height * 0.69),
      0.74,
    );
    _paintMatchaCup(canvas, Offset(size.width * 0.46, size.height * 0.62), 17);
    _paintWindowStreaks(
      canvas,
      Rect.fromLTWH(
        size.width * 0.03,
        size.height * 0.06,
        size.width * 0.94,
        size.height * 0.52,
      ),
    );
  }

  // Paints warm pendant-style string lights across a scene.
  void _paintStringLights(Canvas canvas, Size size, double y) {
    final wire = Paint()
      ..color = const Color(0xFF2E211B).withValues(alpha: 0.55)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.08, y),
      Offset(size.width * 0.92, y),
      wire,
    );
    for (var index = 0; index < 8; index++) {
      final center = Offset(size.width * (0.12 + index * 0.11), y + 10);
      canvas.drawCircle(center, 4, Paint()..color = theme.accent);
      canvas.drawCircle(
        center,
        9,
        Paint()..color = theme.accent.withValues(alpha: 0.15),
      );
    }
  }

  // Paints a compact cafe table with chairs and a cup.
  void _paintSmallTableSet(Canvas canvas, Offset center) {
    _paintCafeChair(canvas, center.translate(-34, 12), 0.62);
    _paintCafeChair(canvas, center.translate(34, 12), 0.62);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 72, height: 34),
      Paint()..color = const Color(0xFF6B422C),
    );
    _paintCup(canvas, center.translate(4, -4), 9, theme.accent);
  }

  // Paints a simple chair silhouette for cafe-like themes.
  void _paintCafeChair(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = const Color(0xFF4B3325);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 38 * scale, height: 24 * scale),
        const Radius.circular(7),
      ),
      paint,
    );
    canvas.drawLine(
      center.translate(-12 * scale, 10 * scale),
      center.translate(-18 * scale, 34 * scale),
      paint..strokeWidth = 3,
    );
    canvas.drawLine(
      center.translate(12 * scale, 10 * scale),
      center.translate(18 * scale, 34 * scale),
      paint,
    );
  }

  // Paints extra handwritten marks on a chalk menu.
  void _paintMenuScribbles(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFFF7E8C9).withValues(alpha: 0.78)
      ..strokeWidth = 1.4;
    for (var row = 0; row < 7; row++) {
      final y = rect.top + 14 + row * 12;
      canvas.drawLine(
        Offset(rect.left + 18, y),
        Offset(rect.left + 95, y),
        paint,
      );
      canvas.drawLine(
        Offset(rect.left + 120, y),
        Offset(rect.right - 14, y),
        paint,
      );
    }
  }

  // Paints rain or reflection streaks inside a windowed area.
  void _paintWindowStreaks(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFFEAF5F2).withValues(alpha: 0.34)
      ..strokeWidth = 1;
    for (var index = 0; index < 18; index++) {
      final x = rect.left + 8 + index * rect.width / 18;
      canvas.drawLine(
        Offset(x, rect.top + 8),
        Offset(x - 5, rect.bottom - 8),
        paint,
      );
    }
  }

  // Paints ornate rings in the tall library ceiling.
  void _paintCeilingRings(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC59B62).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final scale in [0.14, 0.20, 0.27]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.50, size.height * 0.12),
          width: size.width * scale,
          height: size.height * scale * 0.62,
        ),
        paint,
      );
    }
  }

  // Paints a patterned reading-room rug.
  void _paintPatternedRug(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()..color = const Color(0xFF5D352D).withValues(alpha: 0.78),
    );
    final paint = Paint()
      ..color = theme.accent.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var inset = 8.0; inset < 34; inset += 10) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(inset), const Radius.circular(14)),
        paint,
      );
    }
  }

  // Paints tiny street-light trails below a city view.
  void _paintCityTraffic(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.accent.withValues(alpha: 0.72)
      ..strokeWidth = 2.4;
    for (var index = 0; index < 8; index++) {
      final y = size.height * (0.49 + index * 0.014);
      canvas.drawLine(
        Offset(size.width * 0.08, y),
        Offset(size.width * 0.34, y + 6),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.66, y + 4),
        Offset(size.width * 0.90, y),
        paint,
      );
    }
  }

  // Paints faint window reflections over the midnight city desk.
  void _paintReflectionStreaks(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB9E7F2).withValues(alpha: 0.20)
      ..strokeWidth = 2;
    for (var index = 0; index < 7; index++) {
      final x = size.width * (0.12 + index * 0.12);
      canvas.drawLine(
        Offset(x, size.height * 0.08),
        Offset(x + 34, size.height * 0.50),
        paint,
      );
    }
  }
}
