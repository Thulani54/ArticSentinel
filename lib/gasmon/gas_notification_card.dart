import 'package:flutter/material.dart';
import '../models/device.dart';
import '../widgets/device_alert_card.dart';

class GasNotificationCard extends StatelessWidget {
  const GasNotificationCard({super.key, required this.device});
  final Device device;
  @override
  Widget build(BuildContext context) => DeviceAlertCard(device: device);
}
