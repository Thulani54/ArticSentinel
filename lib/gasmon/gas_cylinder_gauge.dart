/// The cylinder gauge — a painted LPG cylinder whose liquid level animates.
/// Light-theme adaptation of the GasMon instrument gauge: steel outline,
/// brass valve hardware, flame-orange fill.
library;

import 'package:flutter/material.dart';

import 'gas_core.dart';
import '../widgets/mobile_forms.dart';
import 'gas_theme.dart';

const _flameTop = Color(0xFFF97316);
const _flameBottom = Color(0xFFC2410C);

class GasCylinderGauge extends StatelessWidget {
  const GasCylinderGauge({
    super.key,
    required this.fill, // 0..1, animated by the parent
    required this.band,
    required this.levelPct,
    required this.netKg,
    required this.capacityKg,
  });

  final double fill;
  final GasBand band;
  final double levelPct;
  final double netKg;
  final double capacityKg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 300,
      child: CustomPaint(
        painter: _CylinderPainter(
          flat: isPhoneLayout(context),
          fill: fill.clamp(0.0, 1.0),
          valueColor: band == GasBand.low ? GasPalette.crit : GasPalette.ink,
          levelPct: levelPct,
          netKg: netKg,
          capacityKg: capacityKg,
        ),
      ),
    );
  }
}

class _CylinderPainter extends CustomPainter {
  _CylinderPainter({
    required this.flat,
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

  final bool flat;

  static const _steel = Color(0xFF94A3B8);
  static const _emptyFill = Color(0xFFF1F5F9);
  static const _brass = Color(0xFFC9A96A);
  static const _brassDark = Color(0xFFA08347);
  static const _tick = Color(0xFFCBD5E1);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    final bodyLeft = w * 0.08, bodyRight = w * 0.68;
    final bodyTop = h * 0.17, bodyBottom = h * 0.965;
    final bodyW = bodyRight - bodyLeft;
    final bodyH = bodyBottom - bodyTop;
    final cx = (bodyLeft + bodyRight) / 2;
    final shoulderR = bodyW * 0.30;

    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom),
      topLeft: Radius.circular(shoulderR),
      topRight: Radius.circular(shoulderR),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );

    // --- valve hardware (behind the body) ---
    final hwPaint = Paint()..color = _brass;
    final hwStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _brassDark;

    final handwheel = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - w * 0.075, h * 0.035, cx + w * 0.075, h * 0.055),
      const Radius.circular(3),
    );
    canvas.drawRRect(handwheel, hwPaint);
    canvas.drawRRect(handwheel, hwStroke);
    canvas.drawRect(
        Rect.fromLTRB(cx - w * 0.014, h * 0.05, cx + w * 0.014, bodyTop + 6),
        hwPaint);

    // --- body: empty fill ---
    canvas.drawRRect(bodyRect, Paint()..color = _emptyFill);

    // --- liquid, clipped to the body ---
    final surfaceY = bodyBottom - bodyH * fill;
    canvas.save();
    canvas.clipRRect(bodyRect);
    if (fill > 0.003) {
      final liquidRect =
          Rect.fromLTRB(bodyLeft, surfaceY, bodyRight, bodyBottom);
      canvas.drawRect(
        liquidRect,
        Paint()
          ..color = _flameTop
          ..shader = flat
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_flameTop, _flameBottom],
                ).createShader(liquidRect),
      );
      // surface line
      canvas.drawRect(
        Rect.fromLTRB(bodyLeft, surfaceY, bodyRight, surfaceY + 3),
        Paint()..color = GasPalette.flameDeep,
      );
      // highlight stripe
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(bodyLeft + bodyW * 0.14, surfaceY + 8,
              bodyLeft + bodyW * 0.28, bodyBottom - 14),
          const Radius.circular(5),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
    }
    canvas.restore();

    // --- collar ring over the shoulder line ---
    final collar = RRect.fromRectAndRadius(
      Rect.fromLTRB(
          bodyLeft - 3, bodyTop - 2, bodyRight + 3, bodyTop + h * 0.045),
      const Radius.circular(6),
    );
    canvas.drawRRect(collar, hwPaint);
    canvas.drawRRect(collar, hwStroke);

    // --- body outline on top ---
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _steel,
    );

    // --- tick rail ---
    final tp = TextPainter()..textDirection = TextDirection.ltr;
    for (final v in const [0, 25, 50, 75, 100]) {
      final y = bodyBottom - bodyH * v / 100;
      canvas.drawLine(
        Offset(bodyRight + 6, y),
        Offset(bodyRight + 14, y),
        Paint()
          ..color = _tick
          ..strokeWidth = 1.2,
      );
      tp.text = TextSpan(
        text: '$v',
        style: TextStyle(
            fontSize: 9.5,
            color: GasPalette.muted,
            fontWeight: FontWeight.w600),
      );
      tp.layout();
      tp.paint(canvas, Offset(bodyRight + 18, y - tp.height / 2));
    }

    // --- center readout ---
    final pctY = bodyTop + bodyH * 0.42;
    final pct = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )
      ..text = TextSpan(
        text: '${levelPct.round()}%',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: valueColor,
          letterSpacing: -0.5,
        ),
      )
      ..layout();
    pct.paint(canvas, Offset(cx - pct.width / 2, pctY - pct.height / 2));

    final sub = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )
      ..text = TextSpan(
        text:
            '${netKg.toStringAsFixed(1)} of ${capacityKg.toStringAsFixed(1)} kg',
        style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: GasPalette.ink2),
      )
      ..layout();
    sub.paint(canvas, Offset(cx - sub.width / 2, pctY + pct.height / 2 + 4));
  }

  @override
  bool shouldRepaint(_CylinderPainter old) =>
      old.flat != flat ||
      old.fill != fill ||
      old.levelPct != levelPct ||
      old.valueColor != valueColor;
}
