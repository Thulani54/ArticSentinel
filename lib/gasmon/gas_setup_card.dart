/// Cylinder setup: the scale only reports combined weight (cylinder + gas),
/// so the empty-cylinder weight and gas capacity set here turn a scale
/// reading into kilograms of gas and a level percentage.
library;

import '../widgets/mobile_forms.dart';

import 'package:flutter/material.dart';

import 'gas_api.dart';
import 'gas_core.dart';
import 'gas_theme.dart';
import 'gas_widgets.dart';

class GasSetupCard extends StatefulWidget {
  const GasSetupCard({
    super.key,
    required this.config,
    required this.onSave,
    this.scaleGrossKg,
  });

  final GasConfig? config;
  final Future<void> Function(GasConfig) onSave;

  /// Latest combined weight from the scale, for "set empty weight from a
  /// full cylinder". Null when there's no live reading.
  final double? scaleGrossKg;

  @override
  State<GasSetupCard> createState() => _GasSetupCardState();
}

class _GasSetupCardState extends State<GasSetupCard> {
  final _capacity = TextEditingController();
  final _tare = TextEditingController();
  final _price = TextEditingController();
  final _low = TextEditingController();
  final _warn = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _fill(widget.config);
  }

  @override
  void didUpdateWidget(GasSetupCard old) {
    super.didUpdateWidget(old);
    // Refill only when the saved setup changes, not on every data refresh.
    if (old.config?.updatedAt != widget.config?.updatedAt ||
        old.config?.isDefault != widget.config?.isDefault) {
      _fill(widget.config);
    }
  }

  @override
  void dispose() {
    for (final c in [_capacity, _tare, _price, _low, _warn]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double v) =>
      v.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

  void _fill(GasConfig? c) {
    _capacity.text = _fmt(c?.gasCapacityKg ?? 19);
    _tare.text = _fmt(c?.tareKg ?? 15.6);
    _price.text = _fmt(c?.pricePerKg ?? kDefaultPricePerKg);
    _low.text = _fmt(c?.lowPct ?? kLowGasThresholdPct);
    _warn.text = _fmt(c?.warningPct ?? kWarningThresholdPct);
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _applyPreset(int gasKg) {
    final t = kCylinderSizes[gasKg]!;
    setState(() {
      _saved = false;
      _capacity.text = _fmt(gasKg.toDouble());
      _tare.text = _fmt(t.$1);
    });
  }

  void _tareFromFullCylinder() {
    final gross = widget.scaleGrossKg;
    final cap = _num(_capacity);
    if (gross == null || cap == null || cap <= 0) return;
    final t = ((gross - cap) * 10).round() / 10;
    setState(() {
      _saved = false;
      if (t <= 0) {
        _error =
            'The scale reads ${kg1(gross)} — less than a full ${_fmt(cap)} kg '
            'cylinder, so it can\'t be full.';
      } else {
        _error = null;
        _tare.text = _fmt(t);
      }
    });
  }

  Future<void> _save() async {
    final cap = _num(_capacity), tare = _num(_tare), price = _num(_price);
    final low = _num(_low), warn = _num(_warn);
    if ([cap, tare, price, low, warn].contains(null)) {
      setState(() => _error = 'Fill in every field with a number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _saved = false;
    });
    try {
      await widget.onSave(GasConfig(
        gasCapacityKg: cap!,
        tareKg: tare!,
        pricePerKg: price!,
        lowPct: low!,
        warningPct: warn!,
        isDefault: false,
      ));
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cap = _num(_capacity), tare = _num(_tare);
    final full = (cap != null && tare != null) ? cap + tare : null;
    final preset = kCylinderSizes.entries
        .where((e) => e.key.toDouble() == cap && e.value.$1 == tare)
        .map((e) => e.key)
        .firstOrNull;

    Widget field(String label, TextEditingController c, {String? helper}) =>
        TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() => _saved = false),
          decoration: mobileInputDecoration(
              context,
              InputDecoration(
                labelText: label,
                helperText: helper,
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
                isDense: true,
              )),
        );

    return GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GEyebrow('Cylinder setup'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in kCylinderSizes.keys)
                ChoiceChip(
                  label: Text('$size kg'),
                  selected: preset == size,
                  onSelected: (_) => _applyPreset(size),
                ),
              if (preset == null) const Chip(label: Text('Custom')),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, box) {
            final twoCols = box.maxWidth > 520;
            final pairs = [
              [
                field('Empty cylinder weight (kg)', _tare,
                    helper: 'The "TW" stamped on the cylinder collar.'),
                field('Gas when full (kg)', _capacity,
                    helper: full != null
                        ? 'A full cylinder weighs ${kg1(full)} on the scale.'
                        : null),
              ],
              [
                field('Gas price (R per kg)', _price),
                const SizedBox.shrink(),
              ],
              [
                field('Low level alert (%)', _low),
                field('Warning level (%)', _warn),
              ],
            ];
            return Column(children: [
              for (final p in pairs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: twoCols
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Expanded(child: p[0]),
                              const SizedBox(width: 12),
                              Expanded(child: p[1]),
                            ])
                      : Column(children: [
                          p[0],
                          if (p[1] is! SizedBox) ...[
                            const SizedBox(height: 12),
                            p[1]
                          ],
                        ]),
                ),
            ]);
          }),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!,
                  style: gasSmall(context).copyWith(color: GasPalette.crit)),
            ),
          if (_saved)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Setup saved — levels recalculated.',
                  style: gasSmall(context).copyWith(
                      color: GasPalette.good, fontWeight: FontWeight.w700)),
            ),
          Wrap(spacing: 10, runSpacing: 8, children: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: GasPalette.flame),
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving…' : 'Save setup'),
            ),
            if (widget.scaleGrossKg != null)
              OutlinedButton(
                onPressed: _tareFromFullCylinder,
                child: const Text('Set empty weight from a full cylinder'),
              ),
          ]),
        ],
      ),
    );
  }
}
