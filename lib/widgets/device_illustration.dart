import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Type illustrations represent equipment categories, not a specific model.
String deviceIllustrationAsset(String? type) {
  final normalized = (type ?? '').trim().toLowerCase().replaceAll(' ', '_');
  final illustration = switch (normalized) {
    'gas' || 'gas_cylinder' || 'gas_monitor' => 'gas-cylinder',
    'device1' ||
    'refrigerator' ||
    'refrigeration' ||
    'chiller' ||
    'freezer' =>
      'refrigeration',
    'device2' => 'zones',
    'device3' || 'ice_machine' => 'ice-machine',
    'device4' => 'compressor',
    'device5' => 'relay-board',
    'device6' => 'pressure',
    'device7' => 'bottle-scanner',
    _ => 'sensor-board',
  };
  return 'lib/assets/devices/$illustration.svg';
}

String deviceIllustrationLabel(String? type, {required String fallback}) {
  if (['chiller', 'freezer'].contains(type?.trim().toLowerCase())) {
    return fallback;
  }
  return switch (deviceIllustrationAsset(type).split('/').last) {
    'gas-cylinder.svg' => 'Gas cylinder',
    'refrigeration.svg' => 'Refrigeration unit',
    'zones.svg' => 'Multi-zone temperature',
    'ice-machine.svg' => 'Ice machine',
    'compressor.svg' => 'Multi-compressor',
    'relay-board.svg' => 'Relay controller',
    'pressure.svg' => 'Pressure monitor',
    'bottle-scanner.svg' => 'Bottle vetting',
    _ => fallback,
  };
}

class DeviceIllustration extends StatelessWidget {
  const DeviceIllustration({super.key, required this.type, this.size = 68});

  final String? type;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SvgPicture.asset(
          deviceIllustrationAsset(type),
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
}
