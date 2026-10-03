import 'package:flutter/material.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import '../models/device.dart';
import '../screens/device_alert_rules.dart';
import '../services/push_notifications.dart';
import 'mobile_forms.dart';

class DeviceAlertCard extends StatelessWidget {
  const DeviceAlertCard({super.key, required this.device});
  final Device device;
  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout(context)) return _buildPhoneCard(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E5EA))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('My phone alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text(
            'Choose your own thresholds for this device’s readings. Your settings do not change anyone else’s alerts.'),
        const SizedBox(height: 12),
        OutlinedButton(
            onPressed: device.id == null
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DeviceAlertRulesScreen(device: device))),
            child: const Text('Configure my alerts')),
        const SizedBox(height: 8),
        ValueListenableBuilder<String>(
            valueListenable: PushNotifications.instance.status,
            builder: (_, status, __) =>
                Text(status, style: const TextStyle(fontSize: 12))),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: PushNotifications.instance.enable,
            child: const Text('Enable phone alerts')),
      ]));
  }

  Widget _buildPhoneCard(BuildContext context) => GPanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('My phone alerts',
                style: gasTitle(context)
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Set device thresholds for your account only.',
                style: gasBody(context).copyWith(fontSize: 12, height: 1.4)),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
                valueListenable: PushNotifications.instance.status,
                builder: (_, status, __) => Text(status,
                    style: gasSmall(context)
                        .copyWith(fontSize: 11.5, height: 1.35))),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final configure = OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: GasPalette.primary,
                    side: const BorderSide(color: GasPalette.border),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                onPressed: device.id == null
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DeviceAlertRulesScreen(device: device))),
                child: const Text('Configure alerts', textAlign: TextAlign.center),
              );
              final enable = FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: GasPalette.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                onPressed: PushNotifications.instance.enable,
                child: const Text('Enable alerts', textAlign: TextAlign.center),
              );
              if (constraints.maxWidth < 250 ||
                  MediaQuery.textScalerOf(context).scale(12) > 15) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [configure, const SizedBox(height: 8), enable],
                );
              }
              return Row(children: [
                Expanded(child: configure),
                const SizedBox(width: 8),
                Expanded(child: enable),
              ]);
            }),
          ],
        ),
      );
}
