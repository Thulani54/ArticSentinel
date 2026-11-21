import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import '../services/push_notifications.dart';
import '../widgets/app_empty_state.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage(
      {super.key, this.loadDiagnostics, this.sendTest, this.enable});
  final Future<Map<String, dynamic>> Function()? loadDiagnostics;
  final Future<String> Function()? sendTest;
  final Future<void> Function()? enable;
  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _data;
  bool _busy = false;
  String? _error, _message;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await (widget.loadDiagnostics?.call() ??
          PushNotifications.instance.diagnostics());
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Could not check notifications. Check your connection and retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(bool test) async {
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      if (test) {
        final message = await (widget.sendTest?.call() ??
            PushNotifications.instance.sendTest());
        if (mounted) setState(() => _message = message);
      } else {
        await (widget.enable?.call() ?? PushNotifications.instance.enable());
      }
      final data = await (widget.loadDiagnostics?.call() ??
          PushNotifications.instance.diagnostics());
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted)
        setState(() => _error = error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: gasSmall(context)),
        const SizedBox(height: 3),
        Text(value, style: gasTitle(context).copyWith(fontSize: 15)),
      ]));
  @override
  Widget build(BuildContext context) {
    final d = _data;
    final ready = d?['supported'] == true && d?['configured'] == true;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Phone notifications',
          style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text(
          'Check this phone, send a test, and manage notification permissions. Device thresholds are set in My device alerts.'),
      const SizedBox(height: 20),
      if (_busy) const LinearProgressIndicator(),
      if (d != null)
        GPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _row(
                      'Phone support',
                      d['supported'] == true
                          ? 'Available on this phone'
                          : 'Open the installed Android or iPhone app'),
                  if (d['supported'] == true)
                    _row(
                        'App configuration',
                        d['configured'] == true
                            ? 'Configured'
                            : 'Install the configured release build'),
                  if (ready) ...[
                    _row(
                        'Permission',
                        switch (d['permission']) {
                          'authorized' => 'Allowed',
                          'denied' => 'Blocked in phone settings',
                          'notDetermined' => 'Not requested yet',
                          'provisional' => 'Quiet notifications allowed',
                          'ephemeral' => 'Temporarily allowed',
                          _ => 'Not checked',
                        }),
                    if (d.containsKey('system_enabled'))
                      _row(
                          'Android notifications',
                          d['system_enabled'] == true
                              ? 'Allowed'
                              : 'Blocked or unavailable'),
                    if (d.containsKey('channel_enabled'))
                      _row(
                          'Device alerts channel',
                          d['channel_enabled'] == true
                              ? 'Enabled'
                              : 'Disabled or unavailable'),
                    if (d.containsKey('apple_registered'))
                      _row(
                          'Apple registration',
                          d['apple_registered'] == true
                              ? 'Registered'
                              : 'Waiting for Apple registration'),
                    _row(
                        'Account registration',
                        d['registered'] == true
                            ? 'This phone is registered'
                            : 'Enable notifications to register'),
                    _row(
                        'Server delivery',
                        d['delivery_configured'] == true
                            ? 'Configured'
                            : 'Not confirmed'),
                    if (d['pending_alerts'] != null)
                      _row(
                          'Alerts awaiting delivery', '${d['pending_alerts']}'),
                    if (d['last_alert_accepted_at'] != null)
                      _row('Last alert accepted by provider',
                          '${d['last_alert_accepted_at']}'),
                  ],
                ])),
      if (_error != null || d?['error'] != null)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AppEmptyState(
                compact: true,
                kind: AppEmptyStateKind.offline,
                title: 'Notification check needs attention',
                message: _error ?? d!['error'] as String,
                actionLabel: 'Check again',
                onAction: _busy ? null : _load)),
      if (_message != null)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(_message!,
                semanticsLabel: _message,
                style: TextStyle(color: GasPalette.goodInk))),
      const SizedBox(height: 16),
      if (ready) ...[
        FilledButton(
            onPressed: _busy ? null : () => _action(true),
            child: const Text('Send test notification')),
        OutlinedButton(
            onPressed: _busy ? null : () => _action(false),
            child: const Text('Enable / reconnect notifications')),
        TextButton(
            onPressed: _busy
                ? null
                : () async {
                    await openAppSettings();
                  },
            child: const Text('Open phone settings')),
        const SizedBox(height: 8),
        const Text(
            'A test targets only this phone. If it is accepted but does not appear, check Do Not Disturb, the Device alerts channel, and battery restrictions in your phone settings. You can send one test per minute.'),
      ],
      TextButton(
          onPressed: _busy ? null : _load, child: const Text('Refresh status')),
    ]);
  }
}
