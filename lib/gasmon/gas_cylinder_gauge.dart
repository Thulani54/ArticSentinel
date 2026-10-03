/// A flat cylinder gauge whose liquid height follows the reported gas level.
library;

import 'package:flutter/material.dart';

import '../widgets/mobile_forms.dart';
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
              mobile: isPhoneLayout(context),
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
    required this.mobile,
  });

  final double fill;
  final Color valueColor;
  final double levelPct;
  final double netKg;
  final double capacityKg;
  final bool mobile;

  static const _steel = Color(0xFF8496A5);
  static const _emptyFill = Color(0xFFF2F6F9);
  static const _liquid = Color(0xFFED6A24);
  static const _hardware = Color(0xFF6D7F8D);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bounds = mobile
        ? _mobileBodyBounds(size, capacityKg)
        : Rect.fromLTRB(w * .14, h * .22, w * .76, h * .94);
    final left = bounds.left, right = bounds.right;
    final top = bounds.top, bottom = bounds.bottom;
    final width = right - left, height = bottom - top;
    final cx = (left + right) / 2;
    final shoulder = width * .27;
    final body = mobile
        ? _tankBody(bounds)
        : (Path()
          ..moveTo(left, top + shoulder)
          ..quadraticBezierTo(left, top + 8, cx - width * .17, top)
          ..lineTo(cx + width * .17, top)
          ..quadraticBezierTo(right, top + 8, right, top + shoulder)
          ..lineTo(right, bottom - 18)
          ..quadraticBezierTo(right, bottom, right - 18, bottom)
          ..lineTo(left + 18, bottom)
          ..quadraticBezierTo(left, bottom, left, bottom - 18)
          ..close());

    if (mobile) {
      _paintTankHardware(canvas, bounds);
    } else {
      // Keep the existing wide-screen illustration unchanged.
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
    }
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
    final readoutY = top + height * (mobile ? .43 : .34);
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
            fontSize: mobile && width < 140 ? 28 : 32,
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

  // These are illustrative proportions, not dimensions of a specific make.
  // Interpolation supports custom capacities and avoids a different silhouette
  // when a saved 9 kg capacity arrives as 9.000000000000002 after subtraction.
  Rect _mobileBodyBounds(Size size, double capacity) {
    const profiles = [
      (kg: 5.0, width: .50, top: .435),
      (kg: 9.0, width: .66, top: .32),
      (kg: 14.0, width: .63, top: .265),
      (kg: 19.0, width: .61, top: .22),
      (kg: 48.0, width: .49, top: .17),
    ];
    final kg = capacity.isFinite && capacity > 0
        ? capacity.clamp(profiles.first.kg, profiles.last.kg)
        : 19.0;
    var width = profiles.last.width;
    var top = profiles.last.top;
    for (var i = 1; i < profiles.length; i++) {
      final a = profiles[i - 1], b = profiles[i];
      if (kg <= b.kg) {
        final t = (kg - a.kg) / (b.kg - a.kg);
        width = a.width + (b.width - a.width) * t;
        top = a.top + (b.top - a.top) * t;
        break;
      }
    }
    return Rect.fromLTRB(
      size.width * (.45 - width / 2),
      size.height * top,
      size.width * (.45 + width / 2),
      size.height * .9,
    );
  }

  Path _tankBody(Rect body) {
    final cx = body.center.dx, width = body.width;
    final dome = width * .29;
    final heel = width * .18;
    return Path()
      ..moveTo(cx - width * .14, body.top)
      ..lineTo(cx + width * .14, body.top)
      ..cubicTo(body.right - width * .13, body.top + 3, body.right,
          body.top + dome * .5, body.right, body.top + dome)
      ..lineTo(body.right, body.bottom - heel)
      ..cubicTo(body.right, body.bottom - 5, cx + width * .26, body.bottom,
          cx + width * .13, body.bottom)
      ..lineTo(cx - width * .13, body.bottom)
      ..cubicTo(cx - width * .26, body.bottom, body.left, body.bottom - 5,
          body.left, body.bottom - heel)
      ..lineTo(body.left, body.top + dome)
      ..cubicTo(body.left, body.top + dome * .5, body.left + width * .13,
          body.top + 3, cx - width * .14, body.top)
      ..close();
  }

  void _paintTankHardware(Canvas canvas, Rect body) {
    final cx = body.center.dx, width = body.width;
    final steel = Paint()..color = _hardware;
    const brass = Color(0xFFB78B46);

    // The foot ring sits behind the curved bottom of the pressure vessel.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - width * .31, body.bottom - 12, cx + width * .31,
            body.bottom + 14),
        const Radius.circular(5),
      ),
      steel,
    );
    for (final side in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx + side * width * .2, body.bottom + 8),
              width: width * .10,
              height: 3),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFDCE6EC),
      );
    }

    // A short brass valve is recessed inside the protective carrying guard.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - 5, body.top - 23, cx + 5, body.top + 2),
        const Radius.circular(2),
      ),
      Paint()..color = brass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + 2, body.top - 17, cx + 16, body.top - 9),
        const Radius.circular(2),
      ),
      Paint()..color = brass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - 11, body.top - 26, cx + 11, body.top - 21),
        const Radius.circular(2),
      ),
      steel,
    );

    final guardWidth = width * .48;
    final guard = Path()
      ..moveTo(cx - guardWidth / 2, body.top + 5)
      ..lineTo(cx - guardWidth / 2, body.top - 32)
      ..quadraticBezierTo(cx - guardWidth / 2, body.top - 42,
          cx - guardWidth / 2 + 10, body.top - 42)
      ..lineTo(cx + guardWidth / 2 - 10, body.top - 42)
      ..quadraticBezierTo(cx + guardWidth / 2, body.top - 42,
          cx + guardWidth / 2, body.top - 32)
      ..lineTo(cx + guardWidth / 2, body.top + 5);
    canvas.drawPath(
        guard,
        Paint()
          ..color = _hardware
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_CylinderPainter old) =>
      old.fill != fill ||
      old.levelPct != levelPct ||
      old.valueColor != valueColor ||
      old.netKg != netKg ||
      old.capacityKg != capacityKg ||
      old.mobile != mobile;
}
