import '../widgets/app_tone.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../gasmon/gas_theme.dart';
import '../models/device.dart';
import '../onboarding/setup_flow_frame.dart';
import '../services/unit_links.dart';
import '../widgets/device_illustration.dart';

/// Shared look for the Maintenance screens: job cards, status and priority
/// pills, stat tiles and section headers, matching the setup flows.

/// Devices by id, so maintenance records (which only carry the device's id
/// and name) can show the device's illustration and its unit.
class MaintenanceEquipment {
  MaintenanceEquipment._();
  static Map<int, Device> _byId = {};
  static DateTime? _loadedAt;

  static Future<void> refresh({bool force = false}) async {
    if (!force &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(minutes: 2))
      return;
    try {
      _byId = {
        for (final d in await UnitLinks.devices())
          if (d.id != null) d.id!: d
      };
      _loadedAt = DateTime.now();
    } catch (_) {}
  }

  static Device? of(dynamic deviceJson) {
    if (deviceJson is! Map) return null;
    final id = deviceJson['id'];
    if (id is int) return _byId[id];
    // Some lists (reminders) only carry the hardware ID.
    final hardware = deviceJson['device_id'];
    if (hardware is String) {
      for (final d in _byId.values) {
        if (d.deviceId == hardware) return d;
      }
    }
    return null;
  }
}

DateTime? _parse(dynamic raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

/// "Today 14:00", "Tomorrow 09:00", "Fri 10 Oct, 09:00", "Overdue · 2 days".
String maintenanceWhen(dynamic raw, {bool done = false}) {
  final at = _parse(raw);
  if (at == null) return 'No date';
  final now = DateTime.now();
  final days =
      DateUtils.dateOnly(at).difference(DateUtils.dateOnly(now)).inDays;
  final time = DateFormat('HH:mm').format(at);
  if (!done && at.isBefore(now)) {
    final late = now.difference(at);
    final amount = late.inDays >= 1
        ? '${late.inDays} day${late.inDays == 1 ? '' : 's'}'
        : late.inHours >= 1
            ? '${late.inHours} h'
            : '${late.inMinutes} min';
    return 'Overdue · $amount';
  }
  if (days == 0) return 'Today $time';
  if (days == 1) return 'Tomorrow $time';
  if (days == -1) return 'Yesterday $time';
  if (days > 1 && days < 7) return '${DateFormat('EEEE').format(at)} $time';
  return DateFormat(at.year == now.year ? 'EEE d MMM, HH:mm' : 'd MMM yyyy')
      .format(at);
}

bool maintenanceIsLate(Map<String, dynamic> r) {
  final status = '${r['status']}';
  if (status == 'completed' || status == 'cancelled') return false;
  if (r['is_overdue'] == true || status == 'overdue') return true;
  final at = _parse(r['scheduled_date']);
  return at != null && at.isBefore(DateTime.now()) && status == 'scheduled';
}

({Color bg, Color fg, IconData icon}) maintenanceStatusStyle(String? status) =>
    switch (status) {
      'completed' => (
          bg: GasPalette.goodSoft,
          fg: GasPalette.goodInk,
          icon: Iconsax.tick_circle
        ),
      'in_progress' => (
          bg: GasPalette.seriesSoft,
          fg: GasPalette.series,
          icon: Iconsax.play_circle
        ),
      'overdue' => (
          bg: GasPalette.critSoft,
          fg: GasPalette.critInk,
          icon: Iconsax.danger
        ),
      'cancelled' => (
          bg: GasPalette.panelAlt,
          fg: GasPalette.ink2,
          icon: Iconsax.close_circle
        ),
      'on_hold' => (
          bg: GasPalette.warnSoft,
          fg: GasPalette.warnInk,
          icon: Iconsax.pause_circle
        ),
      _ => (
          bg: GasPalette.panelAlt,
          fg: GasPalette.ink,
          icon: Iconsax.calendar_1
        ),
    };

({Color bg, Color fg}) maintenancePriorityStyle(String? priority) =>
    switch (priority) {
      'critical' => (bg: GasPalette.critSoft, fg: GasPalette.critInk),
      'high' => (bg: GasPalette.warnSoft, fg: GasPalette.warnInk),
      'low' => (bg: GasPalette.panelAlt, fg: GasPalette.ink2),
      _ => (bg: GasPalette.seriesSoft, fg: GasPalette.series),
    };

String _title(String? s) => s == null || s.isEmpty
    ? ''
    : '${s[0].toUpperCase()}${s.substring(1).replaceAll('_', ' ')}';

class MaintenancePill extends StatelessWidget {
  const MaintenancePill(
      {super.key,
      required this.text,
      required this.bg,
      required this.fg,
      this.icon});
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4)
          ],
          Text(text,
              style: SetupFlowFrame.text(11.5,
                  weight: FontWeight.w700, color: fg)),
        ]),
      );
}

/// One maintenance job: what, on which equipment, when, who, and its state.
class MaintenanceJobCard extends StatelessWidget {
  const MaintenanceJobCard({
    super.key,
    required this.record,
    required this.onOpen,
    this.onStart,
    this.onComplete,
    this.compact = false,
  });

  final Map<String, dynamic> record;
  final VoidCallback onOpen;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final device = MaintenanceEquipment.of(r['device']);
    final deviceName =
        '${(r['device'] is Map ? r['device']['name'] : null) ?? 'Equipment'}';
    final unit = device?.connectedUnit?.name;
    final type =
        '${(r['maintenance_type'] is Map ? r['maintenance_type']['name'] : null) ?? 'Maintenance'}';
    final status = '${r['status'] ?? 'scheduled'}';
    final late = maintenanceIsLate(r);
    final done = status == 'completed' || status == 'cancelled';
    final s = maintenanceStatusStyle(late ? 'overdue' : status);
    final p = maintenancePriorityStyle('${r['priority']}');
    final assignee = r['assigned_to'] is Map
        ? '${r['assigned_to']['full_name'] ?? r['assigned_to']['username'] ?? ''}'
            .trim()
        : '';
    final description = '${r['work_description'] ?? ''}'.trim();
    return Material(
      color: Tone.bg(Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: late ? GasPalette.critLine : GasPalette.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: GasPalette.panelAlt,
                    borderRadius: BorderRadius.circular(12)),
                child: DeviceIllustration(type: device?.deviceType, size: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SetupFlowFrame.text(15.5,
                              weight: FontWeight.w700)),
                      Text(unit == null ? deviceName : '$unit · $deviceName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              SetupFlowFrame.text(13, color: GasPalette.ink2)),
                    ]),
              ),
              Icon(Icons.chevron_right_rounded, color: GasPalette.ink2),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(late ? Iconsax.danger : Iconsax.calendar_1,
                  size: 15, color: late ? GasPalette.critInk : GasPalette.ink2),
              const SizedBox(width: 6),
              Expanded(
                child: Text(maintenanceWhen(r['scheduled_date'], done: done),
                    style: SetupFlowFrame.text(13,
                        weight: FontWeight.w600,
                        color: late ? GasPalette.critInk : GasPalette.ink)),
              ),
              if (assignee.isNotEmpty) ...[
                Icon(Iconsax.user, size: 15, color: GasPalette.ink2),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(assignee,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SetupFlowFrame.text(12.5, color: GasPalette.ink2)),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              MaintenancePill(
                  text: late
                      ? 'Overdue'
                      : '${r['status_display'] ?? _title(status)}',
                  bg: s.bg,
                  fg: s.fg,
                  icon: s.icon),
              MaintenancePill(
                  text:
                      '${r['priority_display'] ?? _title('${r['priority']}')} priority',
                  bg: p.bg,
                  fg: p.fg),
            ]),
            if (!compact && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
            ],
            if (!compact && (onStart != null || onComplete != null)) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: onStart != null
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            visualDensity: VisualDensity.compact),
                        onPressed: onStart,
                        icon: const Icon(Iconsax.play, size: 16),
                        label: const Text('Start job'))
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            visualDensity: VisualDensity.compact),
                        onPressed: onComplete,
                        icon: const Icon(Iconsax.tick_circle, size: 16),
                        label: const Text('Mark complete')),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class MaintenanceStatTile extends StatelessWidget {
  const MaintenanceStatTile(
      {super.key,
      required this.value,
      required this.label,
      required this.icon,
      this.tone,
      this.onTap});
  final String value;
  final String label;
  final IconData icon;
  final Color? tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Material(
          color: Tone.bg(Colors.white),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: GasPalette.border)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: tone ?? GasPalette.series),
                    const SizedBox(height: 6),
                    Text(value,
                        style: SetupFlowFrame.text(22,
                            weight: FontWeight.w800,
                            color: tone ?? GasPalette.ink)),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SetupFlowFrame.text(12, color: GasPalette.ink2)),
                  ]),
            ),
          ),
        ),
      );
}

class MaintenanceSectionHeader extends StatelessWidget {
  const MaintenanceSectionHeader(
      {super.key, required this.title, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: SetupFlowFrame.text(17, weight: FontWeight.w700)),
              if (subtitle != null)
                Text(subtitle!,
                    style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
            ]),
          ),
          if (action != null) action!,
        ]),
      );
}
