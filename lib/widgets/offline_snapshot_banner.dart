import 'app_tone.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/offline_read_client.dart';
import '../gasmon/gas_theme.dart';

/// Retry while this view is visible, and immediately on returning to the app.
class OfflineSnapshotBanner extends StatefulWidget {
  const OfflineSnapshotBanner(
      {super.key, required this.client, required this.onRetry});
  final OfflineReadClient client;
  final Future<void> Function() onRetry;
  @override
  State<OfflineSnapshotBanner> createState() => _OfflineSnapshotBannerState();
}

class _OfflineSnapshotBannerState extends State<OfflineSnapshotBanner>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _retrying = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _retry());
  }

  Future<void> _retry() async {
    if (_retrying ||
        widget.client.status.value == null ||
        !mounted ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused)
      return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } catch (_) {/* Owning view shows its request error. */} finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _retry();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<OfflineSnapshot?>(
        valueListenable: widget.client.status,
        builder: (context, snapshot, _) => snapshot == null
            ? const SizedBox.shrink()
            : Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Tone.bg(const Color(0xFFFFF4DE)),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.cloud_off_outlined, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text('Saved readings',
                                style: TextStyle(fontWeight: FontWeight.w700)))
                      ]),
                      const SizedBox(height: 6),
                      Text(
                          'Connection unavailable. Downloaded ${DateFormat('d MMM y, HH:mm').format(snapshot.savedAt.toLocal())}. Reading times are shown with each device. Retrying automatically.',
                          style: TextStyle(color: GasPalette.ink)),
                      TextButton(
                          onPressed: _retrying ? null : _retry,
                          child: Text(_retrying ? 'Reconnecting…' : 'Try now')),
                    ]),
              ),
      );
}
