import 'app_tone.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../gasmon/gas_theme.dart';
import '../models/device.dart';
import '../onboarding/setup_flow_frame.dart';
import '../services/unit_links.dart';
import 'device_illustration.dart';

/// Phone: a tall bottom sheet. Web / wide: a centred dialog.
Future<T?> showAdaptiveSheet<T>(BuildContext context, WidgetBuilder builder) {
  if (MediaQuery.sizeOf(context).width >= SetupFlowFrame.wideBreakpoint) {
    return showDialog<T>(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Tone.bg(Colors.white),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          child: builder(c),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Tone.bg(Colors.white),
    showDragHandle: true,
    builder: (c) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * .88),
      child: builder(c),
    ),
  );
}

/// From a unit: tick the devices that monitor it. Returns true when saved.
Future<bool> showLinkDevicesToUnit(BuildContext context,
    {required String unitId, required String unitName}) async {
  final saved = await showAdaptiveSheet<bool>(
      context, (_) => _LinkDevicesToUnit(unitId: unitId, unitName: unitName));
  return saved == true;
}

/// From a device: choose its unit (or none). Returns true when saved.
Future<bool> showLinkUnitToDevice(BuildContext context,
    {required Device device}) async {
  final saved = await showAdaptiveSheet<bool>(
      context, (_) => _LinkUnitToDevice(device: device));
  return saved == true;
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.action,
    this.error,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final Widget action;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            SetupFlowFrame.text(20, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: SetupFlowFrame.text(14, color: GasPalette.ink2)),
                  ]),
            ),
            Flexible(child: child),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: SetupNote(
                    icon: Iconsax.info_circle,
                    title: 'Not saved',
                    text: error!,
                    tone: SetupNoteTone.error),
              ),
            Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: action),
          ]);
}

Widget _primary(String label, VoidCallback? onPressed, {bool busy = false}) =>
    FilledButton(
      style: FilledButton.styleFrom(
          backgroundColor: GasPalette.primary,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder()),
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    );

Widget _loadingOrError(String? error, VoidCallback retry) => Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: error == null
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Column(mainAxisSize: MainAxisSize.min, children: [
                Text(error,
                    textAlign: TextAlign.center,
                    style: SetupFlowFrame.text(14, color: GasPalette.ink2)),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: retry, child: const Text('Try again')),
              ]),
      ),
    );

// --- Unit → devices ------------------------------------------------------------

class _LinkDevicesToUnit extends StatefulWidget {
  const _LinkDevicesToUnit({required this.unitId, required this.unitName});
  final String unitId;
  final String unitName;
  @override
  State<_LinkDevicesToUnit> createState() => _LinkDevicesToUnitState();
}

class _LinkDevicesToUnitState extends State<_LinkDevicesToUnit> {
  List<Device>? _devices;
  final Set<int> _chosen = {};
  String? _loadError;
  String? _saveError;
  bool _saving = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final devices = await UnitLinks.devices();
      if (!mounted) return;
      setState(() {
        _devices = devices.where((d) => d.id != null).toList()
          ..sort((a, b) => _rank(a).compareTo(_rank(b)));
        _chosen
          ..clear()
          ..addAll(_devices!
              .where((d) => d.connectedUnit?.id == widget.unitId)
              .map((d) => d.id!));
      });
    } catch (e) {
      if (mounted)
        setState(() =>
            _loadError = e is String ? e : 'Your devices could not be loaded.');
    }
  }

  // Linked here first, then free devices, then ones on other units.
  int _rank(Device d) => d.connectedUnit?.id == widget.unitId
      ? 0
      : d.connectedUnit == null
          ? 1
          : 2;

  Future<void> _save() async {
    final changes = _devices!
        .where((d) =>
            _chosen.contains(d.id) != (d.connectedUnit?.id == widget.unitId))
        .toList();
    if (changes.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      for (final d in changes) {
        await UnitLinks.setUnit(
            d.id!, _chosen.contains(d.id) ? widget.unitId : null);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            '${e is String ? e : 'Some links were not saved.'} Reopen to check which devices changed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = _devices;
    final shown = devices
        ?.where((d) => '${d.name} ${d.deviceId} ${d.location ?? ''}'
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();
    final changes = devices == null
        ? 0
        : devices
            .where((d) =>
                _chosen.contains(d.id) !=
                (d.connectedUnit?.id == widget.unitId))
            .length;
    return _SheetScaffold(
      title: 'Link devices',
      subtitle: 'Choose the devices that monitor ${widget.unitName}.',
      error: _saveError,
      action: _primary(
          changes == 0
              ? 'Done'
              : 'Save ${changes == 1 ? '1 change' : '$changes changes'}',
          devices == null ? null : _save,
          busy: _saving),
      child: devices == null
          ? _loadingOrError(_loadError, _load)
          : devices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                      'You have no devices yet. Add one in Equipment, then link it here.',
                      style: SetupFlowFrame.text(14, color: GasPalette.ink2)),
                )
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  if (devices.length > 6)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search devices',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: GasPalette.panelAlt,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final d in shown!)
                          CheckboxListTile(
                            value: _chosen.contains(d.id),
                            onChanged: _saving
                                ? null
                                : (v) => setState(() => v == true
                                    ? _chosen.add(d.id!)
                                    : _chosen.remove(d.id)),
                            secondary: DeviceIllustration(
                                type: d.deviceType, size: 40),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            title: Text(d.name,
                                style: SetupFlowFrame.text(15,
                                    weight: FontWeight.w600)),
                            subtitle: Text(
                              d.connectedUnit == null ||
                                      d.connectedUnit!.id == widget.unitId
                                  ? d.deviceId
                                  : '${d.deviceId} · now on ${d.connectedUnit!.name}'
                                      '${_chosen.contains(d.id) ? ' — will move here' : ''}',
                              style: SetupFlowFrame.text(12.5,
                                  color: d.connectedUnit != null &&
                                          d.connectedUnit!.id !=
                                              widget.unitId &&
                                          _chosen.contains(d.id)
                                      ? GasPalette.warnInk
                                      : GasPalette.ink2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
    );
  }
}

// --- Device → unit -------------------------------------------------------------

class _LinkUnitToDevice extends StatefulWidget {
  const _LinkUnitToDevice({required this.device});
  final Device device;
  @override
  State<_LinkUnitToDevice> createState() => _LinkUnitToDeviceState();
}

class _LinkUnitToDeviceState extends State<_LinkUnitToDevice> {
  List<UnitSummary>? _units;
  String? _choice;
  String? _loadError;
  String? _saveError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _choice = widget.device.connectedUnit?.id;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final units = await UnitLinks.units();
      if (mounted) setState(() => _units = units);
    } catch (e) {
      if (mounted)
        setState(() =>
            _loadError = e is String ? e : 'Your units could not be loaded.');
    }
  }

  Future<void> _save() async {
    if (_choice == widget.device.connectedUnit?.id) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await UnitLinks.setUnit(widget.device.id!, _choice);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = e is String ? e : 'The link was not saved.';
        });
      }
    }
  }

  Widget _option(String? id, String title, String subtitle, Widget leading) {
    final selected = _choice == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? GasPalette.seriesSoft : Tone.bg(Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: selected ? GasPalette.series : GasPalette.border,
                width: selected ? 1.5 : 1)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _saving ? null : () => setState(() => _choice = id),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style:
                              SetupFlowFrame.text(15, weight: FontWeight.w700)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: SetupFlowFrame.text(12.5,
                                color: GasPalette.ink2)),
                    ]),
              ),
              Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? GasPalette.series : GasPalette.ink2),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final units = _units;
    return _SheetScaffold(
      title: 'Link to a unit',
      subtitle: 'Which refrigeration unit does ${widget.device.name} monitor?',
      error: _saveError,
      action: _primary(
          _choice == widget.device.connectedUnit?.id ? 'Done' : 'Save',
          units == null ? null : _save,
          busy: _saving),
      child: units == null
          ? _loadingOrError(_loadError, _load)
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                  for (final u in units)
                    _option(
                        u.id,
                        u.name,
                        [
                          u.location,
                          if (u.model != null && u.model!.isNotEmpty)
                            'Model ${u.model}'
                        ].whereType<String>().join(' · '),
                        CircleAvatar(
                            radius: 20,
                            backgroundColor: GasPalette.panelAlt,
                            child: Icon(Iconsax.box_1,
                                size: 20, color: GasPalette.series))),
                  _option(
                      null,
                      'No unit',
                      'Keep this device on its own',
                      CircleAvatar(
                          radius: 20,
                          backgroundColor: GasPalette.panelAlt,
                          child: Icon(Iconsax.minus_cirlce,
                              size: 20, color: GasPalette.ink2))),
                  if (units.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                          'No units yet. Add one under Unit Management to link this device.',
                          style:
                              SetupFlowFrame.text(13, color: GasPalette.ink2)),
                    ),
                ]),
    );
  }
}

/// Unit details: the devices monitoring this unit, with "Link devices".
class UnitDevicesPanel extends StatefulWidget {
  const UnitDevicesPanel(
      {super.key, required this.unitId, required this.unitName});
  final String unitId;
  final String unitName;
  @override
  State<UnitDevicesPanel> createState() => _UnitDevicesPanelState();
}

class _UnitDevicesPanelState extends State<UnitDevicesPanel> {
  List<Device>? _devices;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final all = await UnitLinks.devices();
      if (mounted) {
        setState(() => _devices =
            all.where((d) => d.connectedUnit?.id == widget.unitId).toList());
      }
    } catch (e) {
      if (mounted)
        setState(() =>
            _error = e is String ? e : 'Linked devices could not be loaded.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = _devices;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Tone.bg(Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GasPalette.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text('Linked devices',
                  style: SetupFlowFrame.text(16, weight: FontWeight.w700))),
          TextButton.icon(
            onPressed: () async {
              if (await showLinkDevicesToUnit(context,
                  unitId: widget.unitId, unitName: widget.unitName)) {
                _load();
              }
            },
            icon: const Icon(Iconsax.link_2, size: 18),
            label: Text(
                devices == null || devices.isEmpty ? 'Link devices' : 'Change'),
          ),
        ]),
        const SizedBox(height: 4),
        if (devices == null && _error == null)
          const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_error != null)
          Text(_error!, style: SetupFlowFrame.text(13, color: GasPalette.ink2))
        else if (devices!.isEmpty)
          Text(
              'No devices are monitoring this unit yet. Link one to see its readings and schedule its maintenance.',
              style: SetupFlowFrame.text(13, color: GasPalette.ink2))
        else
          for (final d in devices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                DeviceIllustration(type: d.deviceType, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name,
                            style: SetupFlowFrame.text(14,
                                weight: FontWeight.w600)),
                        Text(d.deviceId,
                            style: SetupFlowFrame.text(12,
                                color: GasPalette.ink2)),
                      ]),
                ),
              ]),
            ),
      ]),
    );
  }
}
