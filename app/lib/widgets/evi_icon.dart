import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A direct port of the SVG icon set in design/parts.jsx.
/// Stroke-based, 24×24 viewBox, currentColor.
class EviIcon extends StatelessWidget {
  final String name;
  final double size;
  final double stroke;
  final Color? color;
  const EviIcon(this.name, {super.key, this.size = 22, this.stroke = 1.6, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _IconPainter(name: name, stroke: stroke, color: color ?? T.ink),
    );
  }
}

class _IconPainter extends CustomPainter {
  final String name;
  final double stroke;
  final Color color;
  _IconPainter({required this.name, required this.stroke, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fillPaint = Paint()..style = PaintingStyle.fill..color = color;

    void path(String d) {
      // We don't have a full SVG path parser; we use precomputed paths per icon.
    }

    switch (name) {
      case 'home':
        _drawPath(canvas, paint, [
          'M3 11.5 L12 4 L21 11.5',
          'M5 10.5 V20 H19 V10.5',
          'M10 20 v-5 H14 v5',
        ]);
        break;
      case 'list':
        _drawPath(canvas, paint, [
          'M4 7 H20', 'M4 12 H20', 'M4 17 H14',
        ]);
        break;
      case 'plus':
        _drawPath(canvas, paint, ['M12 5 V19', 'M5 12 H19']);
        break;
      case 'people':
        _drawCircle(canvas, paint, 9, 9, 3.2);
        _drawPath(canvas, paint, ['M3 19 C3 16 5.7 14 9 14 S15 16 15 19']);
        _drawCircle(canvas, paint, 17, 8, 2.5);
        _drawPath(canvas, paint, ['M15 14 C18 14 21 15.5 21 18']);
        break;
      case 'mic':
        _rect(canvas, paint, 9, 3, 6, 11, 3);
        _drawPath(canvas, paint, ['M5 11 a7 7 0 0 0 14 0', 'M12 18 V21']);
        break;
      case 'camera':
        _drawPath(canvas, paint, ['M3 8 H6 L8 5.5 H16 L18 8 H21 V19 H3 Z']);
        _drawCircle(canvas, paint, 12, 13, 3.5);
        break;
      case 'pen':
        _drawPath(canvas, paint, ['M4 20 L8 19 L20 7 L17 4 L5 16 L4 20 Z']);
        break;
      case 'sparkle':
      case 'spark2':
        _drawPath(canvas, paint, [
          'M12 3 V9', 'M12 15 V21',
          'M3 12 H9', 'M15 12 H21',
          'M6 6 L9 9', 'M15 15 L18 18',
          'M6 18 L9 15', 'M15 9 L18 6',
        ]);
        break;
      case 'check':
        _drawPath(canvas, paint, ['M5 12.5 L9 16.5 L19 6.5']);
        break;
      case 'x':
        _drawPath(canvas, paint, ['M5 5 L19 19', 'M19 5 L5 19']);
        break;
      case 'arrow-right':
        _drawPath(canvas, paint, ['M5 12 H19', 'M13 6 L19 12 L13 18']);
        break;
      case 'arrow-left':
        _drawPath(canvas, paint, ['M19 12 H5', 'M11 18 L5 12 L11 6']);
        break;
      case 'arrow-up':
        _drawPath(canvas, paint, ['M12 19 V5', 'M6 11 L12 5 L18 11']);
        break;
      case 'arrow-down':
        _drawPath(canvas, paint, ['M12 5 V19', 'M6 13 L12 19 L18 13']);
        break;
      case 'chevron-right':
        _drawPath(canvas, paint, ['M9 6 L15 12 L9 18']);
        break;
      case 'chevron-down':
        _drawPath(canvas, paint, ['M6 9 L12 15 L18 9']);
        break;
      case 'settings':
        _drawCircle(canvas, paint, 12, 12, 3);
        _drawPath(canvas, paint, [
          'M12 2 V5', 'M12 19 V22', 'M2 12 H5', 'M19 12 H22',
          'M5 5 L7 7', 'M17 17 L19 19', 'M5 19 L7 17', 'M17 7 L19 5',
        ]);
        break;
      case 'bell':
        _drawPath(canvas, paint, [
          'M6 9 a6 6 0 0 1 12 0 c0 4 1.5 6 1.5 6 H4.5 S6 13 6 9 Z',
          'M10 19 a2 2 0 0 0 4 0',
        ]);
        break;
      case 'search':
        _drawCircle(canvas, paint, 11, 11, 6);
        _drawPath(canvas, paint, ['M16 16 L20 20']);
        break;
      case 'wallet':
        _rect(canvas, paint, 3, 6, 18, 13, 2);
        _drawPath(canvas, paint, ['M3 10 H21']);
        _drawCircle(canvas, paint, 16, 14.5, 1);
        break;
      case 'pie':
        _drawPath(canvas, paint, [
          'M12 3 V12 H21 a9 9 0 1 1 -9 -9 Z',
          'M14 3 a8 8 0 0 1 7 7 H14 Z',
        ]);
        break;
      case 'calendar':
        _rect(canvas, paint, 3, 5, 18, 16, 2);
        _drawPath(canvas, paint, ['M3 10 H21', 'M8 3 V7', 'M16 3 V7']);
        break;
      case 'tag':
        _drawPath(canvas, paint, ['M3 12 V4 H11 L21 14 L13 22 Z']);
        _drawCircle(canvas, paint, 8, 8, 1.5);
        break;
      case 'cart':
        _drawPath(canvas, paint, ['M3 4 H5 L7.5 15 H18.5 L20.5 7 H7']);
        _drawCircle(canvas, paint, 9, 20, 1.3);
        _drawCircle(canvas, paint, 18, 20, 1.3);
        break;
      case 'cup':
        _drawPath(canvas, paint, [
          'M5 8 H17 V14 a4 4 0 0 1 -4 4 H9 a4 4 0 0 1 -4 -4 Z',
          'M17 9 H19 a2 2 0 0 1 0 4 H17',
          'M8 4 L9 6', 'M12 4 L13 6',
        ]);
        break;
      case 'fuel':
        _rect(canvas, paint, 4, 4, 10, 16, 1);
        _drawPath(canvas, paint, ['M14 9 H16.5 a2 2 0 0 1 2 2 V17 a1.5 1.5 0 0 0 3 0 V8 L19.5 6']);
        break;
      case 'bolt':
      case 'flash':
        _drawPath(canvas, paint, ['M13 3 L5 14 H11 L9 21 L17 10 H11 Z']);
        break;
      case 'house-heart':
        _drawPath(canvas, paint, [
          'M3 11 L12 4 L21 11 V20 H3 Z',
          'M9 14 c0 -1.5 1.5 -2.5 3 -1 c1.5 -1.5 3 -0.5 3 1 c0 2 -3 4 -3 4 s-3 -2 -3 -4 Z',
        ]);
        break;
      case 'play':
        _drawPath(canvas, paint, ['M7 4 L20 12 L7 20 Z']);
        break;
      case 'pause':
        _rect(canvas, paint, 6, 5, 4, 14);
        _rect(canvas, paint, 14, 5, 4, 14);
        break;
      case 'image':
        _rect(canvas, paint, 3, 4, 18, 16, 2);
        _drawCircle(canvas, paint, 9, 10, 2);
        _drawPath(canvas, paint, ['M21 16 L16 11 L7 20']);
        break;
      case 'rotate':
      case 'refresh':
        _drawPath(canvas, paint, [
          'M3 12 a9 9 0 0 1 16 -5 L21 4',
          'M21 4 V9 H16',
          'M21 12 a9 9 0 0 1 -16 5 L3 20',
          'M3 20 V15 H8',
        ]);
        break;
      case 'trash':
        _drawPath(canvas, paint, ['M4 7 H20', 'M9 7 V4 H15 V7', 'M6 7 V20 H18 V7']);
        break;
      case 'star':
        _drawPath(canvas, paint, ['M12 3 L15 9 L22 10 L17 15 L18 22 L12 19 L6 22 L7 15 L2 10 L9 9 Z']);
        break;
      case 'leaf':
        _drawPath(canvas, paint, ['M5 19 c0 -9 6 -15 15 -15 c0 9 -6 15 -15 15 Z', 'M5 19 L12 12']);
        break;
      case 'gift':
        _rect(canvas, paint, 3, 9, 18, 11, 1);
        _drawPath(canvas, paint, ['M3 13 H21', 'M12 9 V20', 'M8 9 c-2 0 -3 -1 -3 -2.5 S6 4 8 4 c2 0 4 5 4 5 s2 -5 4 -5 c2 0 3 1 3 2.5 S18 9 16 9']);
        break;
      case 'baby':
        _drawCircle(canvas, paint, 12, 9, 4);
        _drawCircle(canvas, fillPaint, 9, 9, 0.5);
        _drawCircle(canvas, fillPaint, 15, 9, 0.5);
        _drawPath(canvas, paint, ['M10 12 c0.5 0.5 1 0.8 2 0.8 s1.5 -0.3 2 -0.8', 'M5 21 c1 -4 4 -6 7 -6 s6 2 7 6']);
        break;
      case 'doc':
        _drawPath(canvas, paint, ['M6 3 H15 L19 7 V21 H6 Z', 'M14 3 V8 H19', 'M9 13 H15', 'M9 17 H13']);
        break;
      case 'send':
        _drawPath(canvas, paint, ['M21 4 L3 11 L10 14 L13 21 Z', 'M21 4 L10 15']);
        break;
      case 'lock':
        _rect(canvas, paint, 5, 11, 14, 9, 2);
        _drawPath(canvas, paint, ['M8 11 V8 a4 4 0 0 1 8 0 V11']);
        break;
      case 'globe':
        _drawCircle(canvas, paint, 12, 12, 9);
        _drawPath(canvas, paint, ['M3 12 H21', 'M12 3 a14 14 0 0 1 0 18', 'M12 3 a14 14 0 0 0 0 18']);
        break;
      case 'menu-dots':
        _drawCircle(canvas, fillPaint, 5, 12, 1.2);
        _drawCircle(canvas, fillPaint, 12, 12, 1.2);
        _drawCircle(canvas, fillPaint, 19, 12, 1.2);
        break;
      case 'food':
        _drawCircle(canvas, paint, 12, 12, 9);
        _drawPath(canvas, paint, ['M12 7 V12 L15 14']);
        break;
      case 'web':
        _rect(canvas, paint, 2, 4, 20, 14, 2);
        _drawPath(canvas, paint, ['M2 9 H22']);
        _drawCircle(canvas, fillPaint, 5, 6.5, 0.4);
        _drawCircle(canvas, fillPaint, 8, 6.5, 0.4);
        _drawCircle(canvas, fillPaint, 11, 6.5, 0.4);
        break;
      default:
        _drawCircle(canvas, paint, 12, 12, 9);
    }
  }

  void _drawPath(Canvas canvas, Paint paint, List<String> commands) {
    for (final c in commands) {
      final path = _parsePath(c);
      canvas.drawPath(path, paint);
    }
  }

  void _drawCircle(Canvas canvas, Paint paint, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  void _rect(Canvas canvas, Paint paint, double x, double y, double w, double h, [double r = 0]) {
    final rect = Rect.fromLTWH(x, y, w, h);
    if (r == 0) {
      canvas.drawRect(rect, paint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)), paint);
    }
  }

  /// Tiny path mini-parser: supports M, L, H, V, C, S, A (only the simple cases used above), Z.
  Path _parsePath(String d) {
    final tokens = d.replaceAll(RegExp(r'(?=[A-Za-z])'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim().split(' ');
    final path = Path();
    double cx = 0, cy = 0;
    int i = 0;
    while (i < tokens.length) {
      final t = tokens[i];
      if (t.isEmpty) { i++; continue; }
      final cmd = t[0];
      final rest = t.substring(1).trim();
      List<double> nums = [];
      if (rest.isNotEmpty) nums.add(double.parse(rest));
      i++;
      while (i < tokens.length && double.tryParse(tokens[i]) != null) {
        nums.add(double.parse(tokens[i]));
        i++;
      }
      switch (cmd) {
        case 'M':
          path.moveTo(nums[0], nums[1]); cx = nums[0]; cy = nums[1];
          for (var k = 2; k < nums.length; k += 2) {
            path.lineTo(nums[k], nums[k + 1]); cx = nums[k]; cy = nums[k + 1];
          }
          break;
        case 'L':
          for (var k = 0; k < nums.length; k += 2) {
            path.lineTo(nums[k], nums[k + 1]); cx = nums[k]; cy = nums[k + 1];
          }
          break;
        case 'H':
          for (final n in nums) { path.lineTo(n, cy); cx = n; }
          break;
        case 'V':
          for (final n in nums) { path.lineTo(cx, n); cy = n; }
          break;
        case 'C':
          for (var k = 0; k < nums.length; k += 6) {
            path.cubicTo(nums[k], nums[k+1], nums[k+2], nums[k+3], nums[k+4], nums[k+5]);
            cx = nums[k+4]; cy = nums[k+5];
          }
          break;
        case 'S':
          for (var k = 0; k < nums.length; k += 4) {
            path.cubicTo(cx, cy, nums[k], nums[k+1], nums[k+2], nums[k+3]);
            cx = nums[k+2]; cy = nums[k+3];
          }
          break;
        case 'A':
          // simplified: rx ry xrot largeArc sweep x y
          if (nums.length >= 7) {
            path.arcToPoint(
              Offset(nums[5], nums[6]),
              radius: Radius.elliptical(nums[0], nums[1]),
              rotation: nums[2],
              largeArc: nums[3] != 0,
              clockwise: nums[4] != 0,
            );
            cx = nums[5]; cy = nums[6];
          }
          break;
        case 'Z':
        case 'z':
          path.close();
          break;
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.name != name || old.stroke != stroke || old.color != color;
}
