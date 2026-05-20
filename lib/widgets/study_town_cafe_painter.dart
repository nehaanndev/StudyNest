part of 'study_town_scene.dart';

extension _StudyTownCafePainter on _StudyTownPainter {
  // Paints the warm cafe-bookstore room inspired by the cafe and shelf photos.
  void _paintCafeBookstore(Canvas canvas, Size size) {
    _paintBrickWall(
      canvas,
      Rect.fromLTWH(0, 0, size.width, size.height * 0.58),
    );
    _paintCafeWindow(
      canvas,
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.12,
        size.width * 0.24,
        size.height * 0.30,
      ),
    );
    _paintChalkMenu(
      canvas,
      Rect.fromLTWH(
        size.width * 0.40,
        size.height * 0.09,
        size.width * 0.42,
        size.height * 0.18,
      ),
    );
    _paintBookWall(
      canvas,
      Rect.fromLTWH(
        size.width * 0.58,
        size.height * 0.24,
        size.width * 0.34,
        size.height * 0.33,
      ),
    );
    _paintPendantLamp(
      canvas,
      Offset(size.width * 0.37, size.height * 0.06),
      34,
    );
    _paintPendantLamp(
      canvas,
      Offset(size.width * 0.75, size.height * 0.06),
      42,
    );
    _paintPastryCase(canvas, size);
    _paintCafeTable(
      canvas,
      Offset(size.width * 0.42, size.height * 0.62),
      size.width * 0.34,
    );
    _paintLaptop(
      canvas,
      Offset(size.width * 0.37, size.height * 0.55),
      size.width * 0.18,
      dark: true,
    );
    _paintCup(
      canvas,
      Offset(size.width * 0.54, size.height * 0.58),
      17,
      theme.accent,
    );
    _paintPottedPlant(
      canvas,
      Offset(size.width * 0.12, size.height * 0.62),
      1.0,
    );
  }

  // Paints a brick cafe wall with simple mortar marks.
  void _paintBrickWall(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = const Color(0xFFB97852));
    final mortar = Paint()
      ..color = const Color(0xFFE0B28F).withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var y = rect.top + 12; y < rect.bottom; y += 22) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), mortar);
    }
    for (var row = 0; row < 12; row++) {
      final y = rect.top + row * 22.0;
      final offset = row.isEven ? 0.0 : 28.0;
      for (var x = rect.left + offset; x < rect.right; x += 56) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 22), mortar);
      }
    }
  }

  // Paints a cafe street window with muted outdoor blocks.
  void _paintCafeWindow(Canvas canvas, Rect rect) {
    final frame = Paint()
      ..color = const Color(0xFF6E4B35)
      ..strokeWidth = 3;
    final glass = Paint()
      ..color = const Color(0xFFCFE0E0).withValues(alpha: 0.72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(6), const Radius.circular(8)),
      frame,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      glass,
    );
    for (
      var x = rect.left + rect.width / 3;
      x < rect.right;
      x += rect.width / 3
    ) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), frame);
    }
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 10, rect.bottom - 42, rect.width - 20, 16),
      Paint()..color = const Color(0xFF8AA3A8).withValues(alpha: 0.5),
    );
  }

  // Paints a chalkboard menu strip with handwritten-style strokes.
  void _paintChalkMenu(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF233026),
    );
    final chalk = Paint()
      ..color = const Color(0xFFF2E5C7).withValues(alpha: 0.82)
      ..strokeWidth = 2;
    for (var row = 0; row < 5; row++) {
      final y = rect.top + 18 + row * 15;
      canvas.drawLine(
        Offset(rect.left + 14, y),
        Offset(rect.left + rect.width * 0.42, y),
        chalk,
      );
      canvas.drawLine(
        Offset(rect.left + rect.width * 0.55, y),
        Offset(rect.right - 18, y),
        chalk,
      );
    }
    canvas.drawLine(
      Offset(rect.left + 14, rect.top + 12),
      Offset(rect.left + 86, rect.top + 12),
      Paint()
        ..color = theme.accent
        ..strokeWidth = 3,
    );
  }

  // Paints a grid of bookshelves for the cafe room.
  void _paintBookWall(Canvas canvas, Rect rect) {
    final shelfPaint = Paint()..color = const Color(0xFF38291F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      shelfPaint,
    );
    final bookColors = [
      theme.secondary,
      theme.accent,
      const Color(0xFFE6C09E),
      const Color(0xFFCF7C62),
    ];
    for (var col = 0; col < 5; col++) {
      for (var row = 0; row < 4; row++) {
        final cell = Rect.fromLTWH(
          rect.left + 8 + col * rect.width / 5,
          rect.top + 10 + row * rect.height / 4,
          rect.width / 5 - 12,
          rect.height / 4 - 14,
        );
        canvas.drawRect(cell, Paint()..color = const Color(0xFF211710));
        for (var book = 0; book < 3; book++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                cell.left + 4 + book * 9,
                cell.top + 5,
                6,
                cell.height - 8,
              ),
              const Radius.circular(2),
            ),
            Paint()..color = bookColors[(book + row + col) % bookColors.length],
          );
        }
      }
    }
  }

  // Paints a curved bakery display case in the cafe foreground.
  void _paintPastryCase(Canvas canvas, Size size) {
    final caseRect = Rect.fromLTWH(
      size.width * 0.02,
      size.height * 0.67,
      size.width * 0.40,
      size.height * 0.16,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(caseRect, const Radius.circular(12)),
      Paint()..color = const Color(0xFF5A3A27),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(caseRect.deflate(8), const Radius.circular(10)),
      Paint()..color = const Color(0xFFB8D6DD).withValues(alpha: 0.42),
    );
    for (var index = 0; index < 6; index++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(caseRect.left + 42 + index * 25, caseRect.top + 48),
          width: 20,
          height: 11,
        ),
        Paint()..color = const Color(0xFFD9A35E),
      );
    }
  }

  // Paints a wood cafe table in perspective.
  void _paintCafeTable(Canvas canvas, Offset center, double width) {
    final table = Path()
      ..moveTo(center.dx - width / 2, center.dy)
      ..lineTo(center.dx, center.dy - width * 0.20)
      ..lineTo(center.dx + width / 2, center.dy)
      ..lineTo(center.dx, center.dy + width * 0.22)
      ..close();
    canvas.drawPath(table, Paint()..color = const Color(0xFF9A6240));
    canvas.drawPath(
      table.shift(const Offset(0, 12)),
      Paint()..color = const Color(0xFF77472E).withValues(alpha: 0.75),
    );
  }
}
