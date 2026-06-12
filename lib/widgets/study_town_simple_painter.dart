part of 'study_town_scene.dart';

extension _StudyTownSimplePainter on _StudyTownPainter {
  // Paints a bright illustrated cafe room with shelves, a window, and a desk.
  void _paintSimpleCafeBookstore(Canvas canvas, Size size) {
    _paintSimpleWarmBackdrop(canvas, size, const Color(0xFFF6E7D3));
    _paintSimpleArchedWindow(
      canvas,
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.12,
        size.width * 0.26,
        size.height * 0.28,
      ),
      skyColor: const Color(0xFFD8ECE9),
      frameColor: const Color(0xFF9B7252),
    );
    _paintSimpleShelfWall(
      canvas,
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.16,
        size.width * 0.26,
        size.height * 0.34,
      ),
      shelfColor: const Color(0xFF9D6F4E),
    );
    _paintPendantLamp(
      canvas,
      Offset(size.width * 0.52, size.height * 0.06),
      34,
    );
    _paintSimpleWoodFloor(canvas, size, const Color(0xFFB98358));
    _paintSimpleDesk(
      canvas,
      Rect.fromLTWH(
        size.width * 0.32,
        size.height * 0.49,
        size.width * 0.34,
        size.height * 0.15,
      ),
      topColor: const Color(0xFFA5724F),
      shadowColor: const Color(0xFF754E33),
    );
    _paintLaptop(
      canvas,
      Offset(size.width * 0.49, size.height * 0.50),
      size.width * 0.17,
      dark: false,
    );
    _paintCup(
      canvas,
      Offset(size.width * 0.58, size.height * 0.55),
      15,
      theme.accent,
    );
    _paintPottedPlant(
      canvas,
      Offset(size.width * 0.18, size.height * 0.62),
      0.95,
    );
    _paintPottedPlant(
      canvas,
      Offset(size.width * 0.82, size.height * 0.62),
      0.88,
    );
    _paintSimpleSunGlow(canvas, size, const Alignment(-0.25, -0.1));
  }

  // Paints a warm library illustration with an arched window and reading desk.
  void _paintSimpleRainyLibrary(Canvas canvas, Size size) {
    _paintSimpleWarmBackdrop(canvas, size, const Color(0xFFEAD3B2));
    _paintSimpleCeilingPanels(canvas, size);
    _paintSimpleArchedWindow(
      canvas,
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.10,
        size.width * 0.28,
        size.height * 0.30,
      ),
      skyColor: const Color(0xFFF3E3B2),
      frameColor: const Color(0xFF90674A),
    );
    _paintSimpleShelfWall(
      canvas,
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.22,
        size.width * 0.22,
        size.height * 0.36,
      ),
      shelfColor: const Color(0xFF8A5D3F),
    );
    _paintSimpleShelfWall(
      canvas,
      Rect.fromLTWH(
        size.width * 0.70,
        size.height * 0.22,
        size.width * 0.22,
        size.height * 0.36,
      ),
      shelfColor: const Color(0xFF8A5D3F),
    );
    _paintSimpleWoodFloor(canvas, size, const Color(0xFFC78F60));
    _paintSimpleDesk(
      canvas,
      Rect.fromLTWH(
        size.width * 0.38,
        size.height * 0.54,
        size.width * 0.24,
        size.height * 0.12,
      ),
      topColor: const Color(0xFFA7744D),
      shadowColor: const Color(0xFF765035),
    );
    _paintBookStack(
      canvas,
      Offset(size.width * 0.50, size.height * 0.51),
      0.55,
    );
    _paintPottedPlant(
      canvas,
      Offset(size.width * 0.16, size.height * 0.64),
      0.92,
    );
    _paintPottedPlant(
      canvas,
      Offset(size.width * 0.84, size.height * 0.64),
      0.92,
    );
    _paintSimpleSunGlow(canvas, size, const Alignment(0, -0.1));
  }

  // Paints a cozy illustrated city desk scene with window, monitor, and curtains.
  void _paintSimpleMidnightCity(Canvas canvas, Size size) {
    final background = Offset.zero & size;
    canvas.drawRect(
      background,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D3552), Color(0xFF8C6C59)],
        ).createShader(background),
    );
    _paintSimpleCityWindow(
      canvas,
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.10,
        size.width * 0.50,
        size.height * 0.40,
      ),
    );
    _paintSimpleCurtains(
      canvas,
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.10,
        size.width * 0.12,
        size.height * 0.44,
      ),
    );
    _paintSimpleDeskSurface(canvas, size, const Color(0xFFE0C79B));
    _paintLaptop(
      canvas,
      Offset(size.width * 0.24, size.height * 0.54),
      size.width * 0.18,
      dark: true,
    );
    _paintMonitor(
      canvas,
      Offset(size.width * 0.43, size.height * 0.47),
      size.width * 0.18,
    );
    _paintNotebook(
      canvas,
      Offset(size.width * 0.49, size.height * 0.60),
      size.width * 0.18,
    );
    _paintCup(
      canvas,
      Offset(size.width * 0.33, size.height * 0.63),
      17,
      const Color(0xFFC79057),
    );
    _paintSimpleTulips(canvas, Offset(size.width * 0.56, size.height * 0.47));
    _paintSimpleNightGlow(canvas, size);
  }

  // Paints a soft desk-and-window study room for the matcha theme.
  void _paintSimpleGardenMatcha(Canvas canvas, Size size) {
    _paintSimpleWarmBackdrop(canvas, size, const Color(0xFFEFE3C8));
    _paintSimpleWindow(
      canvas,
      Rect.fromLTWH(
        size.width * 0.62,
        size.height * 0.12,
        size.width * 0.20,
        size.height * 0.22,
      ),
    );
    _paintSimpleShelfWall(
      canvas,
      Rect.fromLTWH(
        size.width * 0.10,
        size.height * 0.18,
        size.width * 0.18,
        size.height * 0.30,
      ),
      shelfColor: const Color(0xFF8C6E52),
    );
    _paintSimpleDeskSurface(canvas, size, const Color(0xFFD5B28A));
    _paintNotebook(
      canvas,
      Offset(size.width * 0.40, size.height * 0.57),
      size.width * 0.20,
    );
    _paintLaptop(
      canvas,
      Offset(size.width * 0.62, size.height * 0.52),
      size.width * 0.22,
      dark: true,
    );
    _paintMatchaCup(canvas, Offset(size.width * 0.28, size.height * 0.61), 18);
    _paintPottedPlant(
      canvas,
      Offset(size.width * 0.18, size.height * 0.60),
      0.9,
    );
    _paintPottedPlant(
      canvas,
      Offset(size.width * 0.82, size.height * 0.59),
      0.8,
    );
    _paintSimpleSunGlow(canvas, size, const Alignment(0.45, -0.15));
  }

  // Paints a cleaner warm wall used by the bright illustrated simple scenes.
  void _paintSimpleWarmBackdrop(Canvas canvas, Size size, Color baseColor) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [baseColor, Color.alphaBlend(theme.surfaceAlt, baseColor)],
        ).createShader(rect),
    );
  }

  // Paints a soft arched window shape used by illustrated interior scenes.
  void _paintSimpleArchedWindow(
    Canvas canvas,
    Rect rect, {
    required Color skyColor,
    required Color frameColor,
  }) {
    final frameRect = rect.inflate(6);
    final archFrame = RRect.fromRectAndCorners(
      frameRect,
      topLeft: Radius.circular(frameRect.width * 0.48),
      topRight: Radius.circular(frameRect.width * 0.48),
      bottomLeft: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
    );
    final archGlass = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(rect.width * 0.46),
      topRight: Radius.circular(rect.width * 0.46),
      bottomLeft: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    );
    canvas.drawRRect(archFrame, Paint()..color = frameColor);
    canvas.drawRRect(archGlass, Paint()..color = skyColor);
    final muntin = Paint()
      ..color = frameColor.withValues(alpha: 0.85)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(rect.center.dx, rect.top + 8),
      Offset(rect.center.dx, rect.bottom),
      muntin,
    );
    canvas.drawLine(
      Offset(rect.left + 14, rect.center.dy),
      Offset(rect.right - 14, rect.center.dy),
      muntin,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        rect.left + 16,
        rect.top + 10,
        rect.width - 32,
        rect.height * 0.36,
      ),
      math.pi,
      math.pi,
      false,
      muntin,
    );
  }

  // Paints a dense but simplified illustrated shelf wall.
  void _paintSimpleShelfWall(
    Canvas canvas,
    Rect rect, {
    required Color shelfColor,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = shelfColor,
    );
    final divider = Paint()
      ..color = const Color(0xFF6E4A34)
      ..strokeWidth = 3;
    for (var row = 1; row < 4; row++) {
      final y = rect.top + row * rect.height / 4;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), divider);
    }
    final bookColors = [
      const Color(0xFF9D4E3F),
      const Color(0xFFC88D4D),
      const Color(0xFF6D7D55),
      const Color(0xFF7B3A3C),
    ];
    final columnWidth = rect.width / 6;
    final rowHeight = rect.height / 4;
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 5; column++) {
        final x = rect.left + 12 + column * columnWidth;
        final y = rect.top + 8 + row * rowHeight;
        for (var book = 0; book < 3; book++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x + book * 11, y, 8, rowHeight - 16),
              const Radius.circular(2),
            ),
            Paint()
              ..color = bookColors[(row + column + book) % bookColors.length],
          );
        }
      }
    }
  }

  // Paints broad illustrated floor planks under the simple room scenes.
  void _paintSimpleWoodFloor(Canvas canvas, Size size, Color floorColor) {
    final floorRect = Rect.fromLTWH(
      0,
      size.height * 0.62,
      size.width,
      size.height * 0.38,
    );
    canvas.drawRect(floorRect, Paint()..color = floorColor);
    final plankPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    for (var index = 0; index < 10; index++) {
      final x = floorRect.left + index * floorRect.width / 10;
      canvas.drawLine(
        Offset(x, floorRect.top),
        Offset(x, floorRect.bottom),
        plankPaint,
      );
    }
  }

  // Paints a simple desk block with a stronger front face for perspective.
  void _paintSimpleDesk(
    Canvas canvas,
    Rect rect, {
    required Color topColor,
    required Color shadowColor,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = topColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 10, rect.bottom - 8, rect.width - 20, 18),
        const Radius.circular(8),
      ),
      Paint()..color = shadowColor,
    );
  }

  // Paints a clean desktop plane for lighter simple desk scenes.
  void _paintSimpleDeskSurface(Canvas canvas, Size size, Color deskColor) {
    final desk = Path()
      ..moveTo(0, size.height * 0.66)
      ..lineTo(size.width, size.height * 0.61)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(desk, Paint()..color = deskColor);
  }

  // Paints a soft circular sun glow behind the simple illustration scenes.
  void _paintSimpleSunGlow(Canvas canvas, Size size, Alignment alignment) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: alignment,
          radius: 0.62,
          colors: [
            const Color(0xFFFFF5CB).withValues(alpha: 0.58),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  // Paints a large city window with simplified skyline silhouettes.
  void _paintSimpleCityWindow(Canvas canvas, Rect rect) {
    final frame = Paint()..color = const Color(0xFFC8A06C);
    canvas.drawRect(rect.inflate(6), frame);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF42506B));
    final skyline = [
      Rect.fromLTWH(rect.left + 18, rect.bottom - 110, 44, 110),
      Rect.fromLTWH(rect.left + 70, rect.bottom - 150, 58, 150),
      Rect.fromLTWH(rect.left + 138, rect.bottom - 92, 54, 92),
      Rect.fromLTWH(rect.left + 202, rect.bottom - 132, 48, 132),
    ];
    for (final building in skyline) {
      canvas.drawRect(building, Paint()..color = const Color(0xFF263249));
      _paintBuildingWindows(canvas, building);
    }
    final divider = Paint()
      ..color = const Color(0xFFE7C9A2).withValues(alpha: 0.7)
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(rect.left + rect.width * 0.5, rect.top),
      Offset(rect.left + rect.width * 0.5, rect.bottom),
      divider,
    );
  }

  // Paints a single curtain block for the cozy city-desk illustration.
  void _paintSimpleCurtains(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = const Color(0xFFDBC8AC),
    );
    final fold = Paint()
      ..color = const Color(0xFFB89D80).withValues(alpha: 0.45)
      ..strokeWidth = 2;
    for (var index = 1; index < 5; index++) {
      final x = rect.left + index * rect.width / 5;
      canvas.drawLine(
        Offset(x, rect.top + 8),
        Offset(x, rect.bottom - 8),
        fold,
      );
    }
  }

  // Paints a small tulip vase used in the cozy city simple room.
  void _paintSimpleTulips(Canvas canvas, Offset center) {
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 14), width: 20, height: 24),
      Paint()..color = const Color(0xFF8C9AA7),
    );
    final stem = Paint()
      ..color = const Color(0xFF5C8150)
      ..strokeWidth = 2;
    for (var index = 0; index < 3; index++) {
      final offset = -8.0 + index * 8;
      canvas.drawLine(
        center.translate(offset, 10),
        center.translate(offset, -12),
        stem,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(offset, -18),
          width: 10,
          height: 16,
        ),
        Paint()..color = const Color(0xFFE9A188),
      );
    }
  }

  // Paints a warm night vignette so the city simple room feels illustrated, not photographic.
  void _paintSimpleNightGlow(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x33261412), Color(0x55261412)],
        ).createShader(rect),
    );
  }

  // Paints wide ceiling panel strokes for the bright simple library scene.
  void _paintSimpleCeilingPanels(Canvas canvas, Size size) {
    final panelPaint = Paint()
      ..color = const Color(0xFFB7926B).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var index = 0; index < 5; index++) {
      final left = size.width * (0.12 + index * 0.14);
      canvas.drawRect(
        Rect.fromLTWH(
          left,
          size.height * 0.03,
          size.width * 0.10,
          size.height * 0.10,
        ),
        panelPaint,
      );
    }
  }
}
