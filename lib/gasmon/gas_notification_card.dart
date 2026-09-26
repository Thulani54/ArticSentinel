import 'package:flutter/material.dart';
import '../services/push_notifications.dart';
import 'gas_widgets.dart';
import 'gas_theme.dart';

class GasNotificationCard extends StatelessWidget {
  const GasNotificationCard({super.key});
  @override
  Widget build(BuildContext context) => GPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Phone alerts', style: gasTitle(context)),
        const SizedBox(height: 8),
        Text(
            'Get notified at 50%, 30%, and 10% remaining, even when the app is closed. Alerts use live scale readings.',
            style: gasBody(context)),
        const SizedBox(height: 10),
        ValueListenableBuilder<String>(
            valueListenable: PushNotifications.instance.status,
            builder: (_, status, __) => Text(status, style: gasSmall(context))),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: PushNotifications.instance.enable,
            child: const Text('Enable phone alerts')),
      ]));
}
