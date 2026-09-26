import 'package:flutter/material.dart';
import '../models/device.dart';
import '../screens/device_alert_rules.dart';
import '../services/push_notifications.dart';

class DeviceAlertCard extends StatelessWidget {
  const DeviceAlertCard({super.key, required this.device});
  final Device device;
  @override
  Widget build(BuildContext context) => Container(
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
