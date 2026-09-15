import 'package:flutter/material.dart';

/// Design tokens — "OGPlayer demo proposal" launcher spec (mirrors the
/// Android/iOS demo apps' InkColors palette).
abstract final class InkColors {
  static const background = Color(0xFF0E0E10);
  static const accent = Color(0xFFF6C445);
  static const rowSurface = Color(0x0BFFFFFF); // #FFF · 4.5%
  static const rowBorder = Color(0x12FFFFFF); // #FFF · 7%
  static const title = Color(0xFFFFFFFF);
  static const description = Color(0x7AFFFFFF); // #FFF · 48%
  static const groupHeader = Color(0x61FFFFFF); // #FFF · 38%
  static const chevron = Color(0x4DFFFFFF); // #FFF · 30%
  static const tagBg = Color(0x17FFFFFF); // #FFF · 9%
  static const iconTile = Color(0x1FF6C445); // accent · 12%
  static const onAccent = Color(0xFF1A1A1A);
}

const sdkVersion = 'v1.1.0';

ThemeData demoTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: InkColors.background,
      colorScheme: const ColorScheme.dark(
        primary: InkColors.accent,
        onPrimary: InkColors.onAccent,
        secondary: InkColors.accent,
        onSecondary: InkColors.onAccent,
        secondaryContainer: InkColors.accent,
        onSecondaryContainer: InkColors.onAccent,
        surface: InkColors.background,
        onSurface: Colors.white,
        surfaceContainerHighest: Color(0xFF1C1C20),
        onSurfaceVariant: Color(0xB3FFFFFF),
        outline: Color(0x33FFFFFF),
      ),
      useMaterial3: true,
    );

/// Compact OGPlayer identity mark (chamfered aperture + play triangle).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _BrandMarkPainter());
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 32.0;
    // Aperture frame white 72% (matches the SDK watermark); only the
    // play triangle is accent yellow.
    final frame = Path()
      ..moveTo(12 * u, 3 * u)
      ..lineTo(29 * u, 3 * u)
      ..lineTo(29 * u, 20 * u)
      ..lineTo(20 * u, 29 * u)
      ..lineTo(3 * u, 29 * u)
      ..lineTo(3 * u, 12 * u)
      ..close();
    canvas.drawPath(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * u
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.72),
    );
    final play = Path()
      ..moveTo(13 * u, 10 * u)
      ..lineTo(22.5 * u, 16 * u)
      ..lineTo(13 * u, 22 * u)
      ..close();
    canvas.drawPath(play, Paint()..color = InkColors.accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
