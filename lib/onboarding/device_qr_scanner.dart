import '../widgets/app_tone.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../products/product_catalog.dart';
import '../widgets/device_illustration.dart';
import 'device_pairing_code.dart';

class DeviceQrScanner extends StatefulWidget {
  const DeviceQrScanner({super.key});

  @override
  State<DeviceQrScanner> createState() => _DeviceQrScannerState();
}

class _DeviceQrScannerState extends State<DeviceQrScanner>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  DevicePairingCode? _code;
  String? _message;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_starting || !mounted || _code != null) return;
    _starting = true;
    try {
      await _controller.start();
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'Camera unavailable. Allow camera access in phone settings, or enter the device ID manually.');
      }
    } finally {
      _starting = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_start());
    } else if (state == AppLifecycleState.inactive) {
      unawaited(_controller.stop());
    }
  }

  void _detect(BarcodeCapture capture) {
    if (_code != null) return;
    for (final barcode in capture.barcodes) {
      final code = DevicePairingCode.parse(barcode.rawValue ?? '');
      if (code == null) continue;
      setState(() {
        _code = code;
        _message = null;
      });
      unawaited(_controller.stop());
      return;
    }
    setState(() => _message =
        'This is not a supported ArticSentinel setup label. You can still enter the printed device ID manually.');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan device label')),
        body: SafeArea(
            child: Column(children: [
          Expanded(
              child: _code == null
                  ? Stack(fit: StackFit.expand, children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: _detect,
                        errorBuilder: (_, __) => ColoredBox(
                            color: Tone.bg(Color(0xFFF1F5F8)),
                            child: Center(
                                child: Padding(
                                    padding: EdgeInsets.all(28),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Iconsax.camera, size: 44),
                                          SizedBox(height: 16),
                                          Text('Camera unavailable',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700)),
                                          SizedBox(height: 8),
                                          Text(
                                              'Allow camera access in phone settings, or use the device ID printed on the label.',
                                              textAlign: TextAlign.center),
                                        ])))),
                      ),
                      IgnorePointer(
                          child: Center(
                              child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Tone.bg(Colors.white), width: 3),
                                      borderRadius:
                                          BorderRadius.circular(24))))),
                    ])
                  : Center(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(28),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            DeviceIllustration(
                                type: _code!.deviceType, size: 120),
                            const SizedBox(height: 20),
                            Text('Check your device',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 12),
                            Text(ProductCatalog.byType(_code!.deviceType)!
                                .title),
                            const SizedBox(height: 8),
                            SelectableText(_code!.deviceId,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            const Text(
                                'Make sure this type and ID match your equipment. You will review the remaining setup before adding it.',
                                textAlign: TextAlign.center),
                          ])),
                    )),
          Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      _message ??
                          (_code == null
                              ? 'Point your camera at the QR code on your ArticSentinel setup label.'
                              : 'Scanning only fills in the type and ID. Your device has not been added.'),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  if (_code != null) ...[
                    FilledButton(
                        onPressed: () => Navigator.of(context).pop(_code),
                        child: const Text('Use these details')),
                    TextButton(
                        onPressed: () {
                          setState(() => _code = null);
                          unawaited(_start());
                        },
                        child: const Text('Scan another label')),
                  ],
                  OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Enter ID manually')),
                ],
              )),
        ])),
      );
}
