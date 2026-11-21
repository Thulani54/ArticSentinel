import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/device.dart';
import '../services/shared_preferences.dart';
import '../widgets/app_empty_state.dart';
import '../gasmon/gas_cylinder_details_dialog.dart';
import 'device_management.dart' show ApiService, DeviceDetailsDialog;

/// Resolve the server device key against the signed-in account's inventory.
/// A push payload never supplies a trusted name, URL or arbitrary device data.
class NotificationDevicePage extends StatefulWidget {
  const NotificationDevicePage(
      {super.key,
      required this.deviceId,
      this.loadDevices,
      this.requestTimeout = const Duration(seconds: 20)});
  final int deviceId;
  final Future<List<Device>> Function()? loadDevices;
  final Duration requestTimeout;
  @override
  State<NotificationDevicePage> createState() => _NotificationDevicePageState();
}

class _NotificationDevicePageState extends State<NotificationDevicePage> {
  Device? _device;
  bool _loading = true;
  String? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(NotificationDevicePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) _load();
  }

  Future<String?> _session() async {
    if (await Sharedprefs.getUserLoggedInSharedPreference() != true)
      return null;
    final user = await Sharedprefs.getUserUidSharedPreference();
    final company = await Sharedprefs.getBusinessUidSharedPreference();
    final token = await Sharedprefs.getAuthTokenPreference();
    if (user == null ||
        user <= 0 ||
        company == null ||
        company <= 0 ||
        token == null ||
        token.isEmpty) return null;
    return '$user:$company:$token';
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _device = null;
    });
    try {
      final session = await _session();
      final company = await Sharedprefs.getBusinessUidSharedPreference();
      if (session == null || company == null) {
        if (mounted && request == _request) context.go('/login');
        return;
      }
      final devices =
          await (widget.loadDevices?.call() ?? ApiService.fetchDevices(company))
              .timeout(widget.requestTimeout);
      if (!mounted || request != _request) return;
      final currentSession = await _session();
      if (!mounted || request != _request) return;
      if (session != currentSession) {
        setState(() => _error =
            'Your account has changed. Reopen this notification from your current account.');
        return;
      }
      final device = devices.where((d) => d.id == widget.deviceId).firstOrNull;
      if (mounted && request == _request)
        setState(() {
          _device = device;
          if (device == null)
            _error = 'This equipment is no longer available to your account.';
        });
    } on TimeoutException {
      if (mounted && request == _request)
        setState(() => _error =
            'The connection is taking too long. Check your network and retry.');
    } catch (_) {
      if (mounted && request == _request)
        setState(() => _error =
            'Could not load this device. Check your connection and retry.');
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null)
      return Scaffold(
          appBar: AppBar(title: const Text('Device alert')),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : AppEmptyState(
                  kind: AppEmptyStateKind.offline,
                  title: 'Device unavailable',
                  message: _error!,
                  actionLabel: 'Retry',
                  onAction: _load));
    return Scaffold(
        body: isGasCylinderType(_device!.deviceType)
            ? GasCylinderDetailsDialog(device: _device!)
            : DeviceDetailsDialog(device: _device!));
  }
}
