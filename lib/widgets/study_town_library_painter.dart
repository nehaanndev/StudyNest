part of 'study_town_scene.dart';

extension _StudyTownLibraryPainter on _StudyTownPainter {
  // Paints the grand rainy library inspired by tall shelves and ornate rooms.
  void _paintRainyLibrary(Canvas canvas, Size size) {
    _paintLibraryCeiling(canvas, size);
    _paintTallShelves(
      canvas,
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.18,
        size.width * 0.25,
        size.height * 0.48,
      ),
    );
    _paintTallShelves(
      canvas,
      Rect.fromLTWH(
        size.width * 0.71,
        size.height * 0.18,
        size.width * 0.25,
        size.height * 0.48,
      ),
    );
    _paintRainWindow(
      canvas,
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.14,
        size.width * 0.30,
        size.height * 0.24,
      ),
    );
    _paintLibraryLadder(canvas, size);
    _paintReadingTable(
      canvas,
      Offset(size.width * 0.50, size.height * 0.62),
      size.width * 0.54,
    );
    _paintBankerLamp(
      canvas,
      Offset(size.width * 0.38, size.height * 0.50),
      1.0,
    );
    _paintBankerLamp(
      canvas,
      Offset(size.width * 0.62, size.height * 0.50),
      0.86,
    );
    _paintBookStack(canvas, Offset(size.width * 0.50, size.height * 0.53), 0.9);
  }

  // Paints an ornate library ceiling and dark back wall.
  void _paintLibraryCeiling(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF3F2D22),
    );
    final archPaint = Paint()
      ..color = const Color(0xFF8A6748)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.20,
        -size.height * 0.18,
        size.width * 0.60,
        size.height * 0.62,
      ),
      0,
      math.pi,
      false,
      archPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.12),
        width: size.width * 0.22,
        height: size.height * 0.13,
      ),
      Paint()..color = const Color(0xFF241A16),
    );
  }

  // Paints tall bookshelves for the library room.
  void _paintTallShelves(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF2B1E18),
    );
    final shelfLine = Paint()
      ..color = const Color(0xFF8A6748)
      ..strokeWidth = 3;
    for (var row = 1; row < 6; row++) {
      final y = rect.top + row * rect.height / 6;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), shelfLine);
    }
    final colors = [
      const Color(0xFF9A5D42),
      const Color(0xFFC5A268),
      const Color(0xFF6F805C),
      const Color(0xFF7D4F45),
    ];
    for (var col = 0; col < 6; col++) {
      for (var row = 0; row < 6; row++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.left + 10 + col * 16,
              rect.top + 8 + row * rect.height / 6,
              9,
              rect.height / 6 - 13,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = colors[(col + row) % colors.length],
        );
      }
    }
  }

  // Paints a rainy window with falling streaks.
  void _paintRainWindow(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(5), const Radius.circular(7)),
      Paint()..color = const Color(0xFF5B3F2D),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF6E8790).withValues(alpha: 0.75),
    );
    final rain = Paint()
      ..color = const Color(0xFFE8F2F2).withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    for (var index = 0; index < 12; index++) {
      final x = rect.left + 10 + index * rect.width / 12;
      canvas.drawLine(
        Offset(x, rect.top + 8),
        Offset(x - 6, rect.bottom - 10),
        rain,
      );
    }
  }

  // Paints a library rolling ladder leaning against shelves.
  void _paintLibraryLadder(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0A46B)
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.24),
      Offset(size.width * 0.56, size.height * 0.66),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.70, size.height * 0.25),
      Offset(size.width * 0.60, size.height * 0.67),
      paint,
    );
    for (var step = 0; step < 6; step++) {
      final y = size.height * (0.31 + step * 0.06);
      canvas.drawLine(
        Offset(size.width * 0.65, y),
        Offset(size.width * 0.69, y + 4),
        paint,
      );
    }
  }

  // Paints a long reading table in the library foreground.
  void _paintReadingTable(Canvas canvas, Offset center, double width) {
    final rect = Rect.fromCenter(
      center: center,
      width: width,
      height: width * 0.18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()..color = const Color(0xFF755136),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 18)),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFF4C3325),
    );
  }

  // Paints a green reading lamp on a table.
  void _paintBankerLamp(Canvas canvas, Offset center, double scale) {
    canvas.drawLine(
      center.translate(0, 18 * scale),
      center.translate(0, 46 * scale),
      Paint()
        ..color = const Color(0xFFBFA15D)
        ..strokeWidth = 3,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 56 * scale, height: 18 * scale),
      Paint()..color = theme.secondary,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 7 * scale),
        width: 50 * scale,
        height: 9 * scale,
      ),
      Paint()..color = theme.accent.withValues(alpha: 0.35),
    );
  }

  // Paints a stack of books.
  void _paintBookStack(Canvas canvas, Offset center, double scale) {
    final colors = [theme.accent, const Color(0xFFB47C5C), theme.secondary];
    for (var index = 0; index < 3; index++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(0, index * 8 * scale),
            width: 82 * scale,
            height: 12 * scale,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = colors[index],
      );
    }
  }
}
