/// A flat cylinder gauge whose liquid height follows the reported gas level.
library;

import 'package:flutter/material.dart';

import 'gas_core.dart';
import 'gas_theme.dart';

class GasCylinderGauge extends StatelessWidget {
  const GasCylinderGauge({
    super.key,
    required this.fill,
    required this.band,
    required this.levelPct,
    required this.netKg,
    required this.capacityKg,
  });

  /// Entrance animation progress, not the cylinder's gas fraction.
  /// Existing callers animate this from zero to one or pass one immediately.
  final double fill;
  final GasBand band;
  final double levelPct;
  final double netKg;
  final double capacityKg;

  @override
  Widget build(BuildContext context) {
    final fraction = levelPct.isFinite ? (levelPct / 100).clamp(0.0, 1.0) : 0.0;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final entrance =
        reducedMotion ? 1.0 : (fill.isFinite ? fill.clamp(0.0, 1.0) : 1.0);
    return Semantics(
      label: 'Gas cylinder level',
      value:
          '${(fraction * 100).round()} percent, ${netKg.toStringAsFixed(1)} of ${capacityKg.toStringAsFixed(1)} kilograms',
      child: SizedBox(
        width: 250,
        height: 300,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: fraction, end: fraction),
          duration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, animatedFraction, _) => CustomPaint(
            painter: _CylinderPainter(
              fill: animatedFraction * entrance,
              valueColor:
                  band == GasBand.low ? GasPalette.crit : GasPalette.ink,
              levelPct: fraction * 100,
              netKg: netKg,
              capacityKg: capacityKg,
            ),
          ),
        ),
      ),
    );
  }
}

class _CylinderPainter extends CustomPainter {
  _CylinderPainter({
    required this.fill,
    required this.valueColor,
    required this.levelPct,
    required this.netKg,
    required this.capacityKg,
  });

  final double fill;
  final Color valueColor;
  final double levelPct;
  final double netKg;
  final double capacityKg;

  static const _steel = Color(0xFF8496A5);
  static const _emptyFill = Color(0xFFF2F6F9);
  static const _liquid = Color(0xFFED6A24);
  static const _hardware = Color(0xFF6D7F8D);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final left = w * .14, right = w * .76;
    final top = h * .22, bottom = h * .94;
    final width = right - left, height = bottom - top;
    final cx = (left + right) / 2;
    final shoulder = width * .27;
    final body = Path()
      ..moveTo(left, top + shoulder)
      ..quadraticBezierTo(left, top + 8, cx - width * .17, top)
      ..lineTo(cx + width * .17, top)
      ..quadraticBezierTo(right, top + 8, right, top + shoulder)
      ..lineTo(right, bottom - 18)
      ..quadraticBezierTo(right, bottom, right - 18, bottom)
      ..lineTo(left + 18, bottom)
      ..quadraticBezierTo(left, bottom, left, bottom - 18)
      ..close();

    // Small valve and collar leave the rounded shoulder visible.
    final hardware = Paint()..color = _hardware;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, h * .075), width: width * .35, height: 10),
        const Radius.circular(5),
      ),
      hardware,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - 5, h * .075, cx + 5, top - 9),
        const Radius.circular(3),
      ),
      hardware,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - width * .20, top - 19, cx + width * .20, top + 4),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFFB7C3CC),
    );
    canvas.drawPath(body, Paint()..color = _emptyFill);

    // Both the rail and the liquid use the same zero/full body bounds.
    // At rest, a 50% level meets the 50 tick rather than filling the cylinder.
    final surfaceY = bottom - height * fill;
    canvas.save();
    canvas.clipPath(body);
    if (fill > 0) {
      canvas.drawRect(Rect.fromLTRB(left, surfaceY, right, bottom),
          Paint()..color = _liquid);
      canvas.drawLine(
          Offset(left, surfaceY),
          Offset(right, surfaceY),
          Paint()
            ..color = GasPalette.flameDeep
            ..strokeWidth = 2);
    }
    canvas.restore();
    canvas.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _steel);

    final text = TextPainter(textDirection: TextDirection.ltr);
    for (final value in const [0, 25, 50, 75, 100]) {
      final y = bottom - height * value / 100;
      canvas.drawLine(
          Offset(right + 7, y),
          Offset(right + 14, y),
          Paint()
            ..color = GasPalette.border
            ..strokeWidth = 1.2);
      text.text = TextSpan(
          text: '$value',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.5,
            color: GasPalette.ink2,
          ));
      text.layout();
      text.paint(canvas, Offset(right + 19, y - text.height / 2));
    }

    // A small flat readout keeps text legible at every liquid level.
    final readoutY = top + height * .34;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, readoutY + 12), width: width * .77, height: 67),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.white,
    );
    final pct = TextPainter(
        textDirection: TextDirection.ltr, textAlign: TextAlign.center)
      ..text = TextSpan(
          text: '${levelPct.round()}%',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: valueColor,
            letterSpacing: -.5,
          ))
      ..layout();
    pct.paint(canvas, Offset(cx - pct.width / 2, readoutY - pct.height / 2));
    final sub = TextPainter(
        textDirection: TextDirection.ltr, textAlign: TextAlign.center)
      ..text = TextSpan(
          text:
              '${netKg.toStringAsFixed(1)} of ${capacityKg.toStringAsFixed(1)} kg',
          style: const TextStyle(
              fontFamily: 'Inter', fontSize: 10.5, color: GasPalette.ink2))
      ..layout(maxWidth: width * .72);
    sub.paint(
        canvas, Offset(cx - sub.width / 2, readoutY + pct.height / 2 + 4));
  }

  @override
  bool shouldRepaint(_CylinderPainter old) =>
      old.fill != fill ||
      old.levelPct != levelPct ||
      old.valueColor != valueColor ||
      old.netKg != netKg ||
      old.capacityKg != capacityKg;
}
