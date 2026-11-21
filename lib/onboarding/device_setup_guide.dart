import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';

/// Step-by-step guidance per device family, shared by the add-device wizard
/// and the device editor. Guidance follows from what each family measures
/// (its probes, clamps or sensors); it does not describe a specific model.
class SetupInstruction {
  const SetupInstruction(this.icon, this.title, this.text);
  final IconData icon;
  final String title;
  final String text;
}

class RangePreset {
  const RangePreset(this.label, this.min, this.max);
  final String label;
  final double min;
  final double max;
}

enum SetupSetting { temperatureRange, cylinderSize, phase }

class DeviceSetupGuide {
  const DeviceSetupGuide({
    required this.fitTitle,
    required this.fitIntro,
    required this.fitScene,
    required this.fitSteps,
    this.settings = const {},
    this.presets = const [],
    this.safety,
    this.connectSteps = _defaultConnect,
  });

  /// Step 2: physically fit the device and, where relevant, set it up.
  final String fitTitle;
  final String fitIntro;
  final String fitScene;
  final List<SetupInstruction> fitSteps;
  final Set<SetupSetting> settings;
  final List<RangePreset> presets;
  final String? safety;

  /// Step 3: power, network and first reading.
  final List<SetupInstruction> connectSteps;

  static const scenes = 'lib/assets/setup';

  static String scene(String name) => '$scenes/$name.svg';

  static DeviceSetupGuide forType(String? type) =>
      _guides[_kind(type)] ?? _guides['device1']!;

  static String _kind(String? type) => switch (type) {
        'chiller' || 'freezer' => 'device1',
        _ => type ?? 'device1',
      };
}

const _defaultConnect = [
  SetupInstruction(Iconsax.flash_1, 'Power on',
      'Check the power light and that every sensor cable is plugged in.'),
  SetupInstruction(Iconsax.wifi, 'Connect to your network',
      'Use the device’s own network settings or your installer’s instructions. Keep this phone online too.'),
  SetupInstruction(Iconsax.chart_2, 'Let it report',
      'Readings appear on your dashboard within a few minutes of the device going online.'),
];

const _coldPresets = [
  RangePreset('Chiller', 0, 5),
  RangePreset('Freezer', -22, -18),
  RangePreset('Display fridge', 2, 8),
];

const _electrical =
    'Only a qualified electrician should fit clamps or wire mains equipment. Switch off and isolate the supply first.';

const _guides = <String, DeviceSetupGuide>{
  'gas_cylinder': DeviceSetupGuide(
    fitTitle: 'Set your cylinder size',
    fitIntro:
        'Your scale weighs the cylinder and the gas together. These two values let us show how much gas is left.',
    fitScene: 'cylinder-on-scale',
    fitSteps: [
      SetupInstruction(Iconsax.weight, 'Stand the cylinder on the scale',
          'Place it in the middle of the plate on a flat, dry floor.'),
    ],
    settings: {SetupSetting.cylinderSize},
    connectSteps: [
      SetupInstruction(Iconsax.flash_1, 'Switch the scale on',
          'Keep it near this phone with Bluetooth turned on.'),
      SetupInstruction(Iconsax.bluetooth, 'Connect it to Wi-Fi',
          'After linking, we’ll guide you through sending your Wi-Fi details to the scale over Bluetooth.'),
      SetupInstruction(Iconsax.chart_2, 'See your gas level',
          'The first weight arrives as soon as the scale is online.'),
    ],
  ),
  'device1': DeviceSetupGuide(
    fitTitle: 'Place the probes',
    fitIntro:
        'The monitor reads the air, the coil and the drain. Good probe positions give honest readings.',
    fitScene: 'probes',
    fitSteps: [
      SetupInstruction(Iconsax.wind, 'Air probe',
          'In the main airflow, away from the door and the evaporator fans.'),
      SetupInstruction(Iconsax.cloud_snow, 'Coil probe',
          'Clipped to the evaporator coil so defrosts and icing show up.'),
      SetupInstruction(Iconsax.drop, 'Drain probe',
          'On the drain line, to catch blocked or frozen drains early.'),
    ],
    settings: {SetupSetting.temperatureRange},
    presets: _coldPresets,
  ),
  'device2': DeviceSetupGuide(
    fitTitle: 'Place a probe in each zone',
    fitIntro:
        'This monitor has up to eight temperature probes. Note which probe goes where so you can name the zones later.',
    fitScene: 'probes',
    fitSteps: [
      SetupInstruction(Iconsax.location, 'One probe per zone',
          'Place each probe in the airflow of the area it should watch.'),
      SetupInstruction(Iconsax.note_1, 'Write down the numbers',
          'Probe 1, probe 2… You can rename the zones in the device’s dashboard.'),
    ],
    settings: {SetupSetting.temperatureRange},
    presets: _coldPresets,
  ),
  'device3': DeviceSetupGuide(
    fitTitle: 'Fit the ice machine sensors',
    fitIntro:
        'The monitor follows the ice, air, high-side and low-side temperatures, the water level and the harvest switch.',
    fitScene: 'probes',
    fitSteps: [
      SetupInstruction(Iconsax.cloud_snow, 'Temperature probes',
          'Ice probe in the bin, air probe in the room air, and the high- and low-side probes on their refrigerant lines.'),
      SetupInstruction(Iconsax.drop, 'Water level',
          'Connect the level sensor in the water reservoir.'),
    ],
    settings: {SetupSetting.temperatureRange},
    presets: [RangePreset('Ice bin', -10, 0)],
    safety: _electrical,
  ),
  'device4': DeviceSetupGuide(
    fitTitle: 'Fit the current clamps',
    fitIntro:
        'The monitor measures the current on each phase of up to eight compressors.',
    fitScene: 'clamps',
    fitSteps: [
      SetupInstruction(Iconsax.flash, 'One clamp per phase',
          'Clamp a single conductor (L1, L2 or L3), never the whole cable, or the reading cancels out.'),
      SetupInstruction(Iconsax.note_1, 'Keep the order',
          'Compressor 1 phase 1 goes on input 1, and so on, so imbalance alerts point at the right phase.'),
    ],
    settings: {SetupSetting.phase},
    safety: _electrical,
  ),
  'device5': DeviceSetupGuide(
    fitTitle: 'Wire the relay channels',
    fitIntro:
        'The controller switches up to sixteen loads and reports which relays are on.',
    fitScene: 'wiring',
    fitSteps: [
      SetupInstruction(Iconsax.data, 'One load per channel',
          'Write down what each relay controls so you can label it later.'),
      SetupInstruction(Iconsax.shield_tick, 'Check the rating',
          'Use a contactor for loads above the relay’s rated current.'),
    ],
    safety: _electrical,
  ),
  'device6': DeviceSetupGuide(
    fitTitle: 'Fit the pressure sensors',
    fitIntro: 'The monitor reads up to eight pressure sensors.',
    fitScene: 'pressure-lines',
    fitSteps: [
      SetupInstruction(Iconsax.setting_4, 'Use the service ports',
          'Fit sensors on the lines you want to watch, rated for the system’s pressure.'),
      SetupInstruction(Iconsax.note_1, 'Keep the order',
          'Note which sensor number is on which line.'),
    ],
    safety:
        'Only a certified refrigeration technician should open or fit to a refrigerant circuit.',
  ),
  'device7': DeviceSetupGuide(
    fitTitle: 'Prepare the station',
    fitIntro:
        'The station scans each bottle and weighs four trays. A clear, level setup keeps scans and weights reliable.',
    fitScene: 'station',
    fitSteps: [
      SetupInstruction(Iconsax.scan_barcode, 'Clear the scanner',
          'Keep the scanning area free of labels and bottles until setup finishes.'),
      SetupInstruction(Iconsax.weight, 'Empty the trays',
          'Start with all four trays empty and level.'),
    ],
    connectSteps: [
      SetupInstruction(Iconsax.flash_1, 'Power on',
          'Wait for the machine to finish starting. Keep the scanning area clear.'),
      SetupInstruction(Iconsax.wifi, 'Connect to your network',
          'Use the machine’s own setup controls to join your site’s network.'),
      SetupInstruction(Iconsax.scan, 'Try a bottle scan',
          'Follow your usual scanning process. Scan and tray readings appear after it reports.'),
    ],
  ),
};
