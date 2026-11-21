import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import 'app_tone.dart';

/// Light, dark or follow the phone. Saved on this device only.
class AppearanceSettingsTile extends StatelessWidget {
  const AppearanceSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return GPanel(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppAppearance.mode,
        builder: (context, mode, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Appearance', style: gasTitle(context)),
            const SizedBox(height: 4),
            Text(
                mode == ThemeMode.system
                    ? 'Matches your phone’s light or dark setting.'
                    : 'Applies to this phone only.',
                style: gasBody(context)),
            const SizedBox(height: 14),
            SegmentedButton<ThemeMode>(
              key: const ValueKey('appearance-mode'),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                foregroundColor: GasPalette.ink2,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: GasPalette.primary,
                side: BorderSide(color: GasPalette.border),
              ),
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Iconsax.mobile, size: 18),
                    label: Text('System')),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Iconsax.sun_1, size: 18),
                    label: Text('Light')),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Iconsax.moon, size: 18),
                    label: Text('Dark')),
              ],
              selected: {mode},
              onSelectionChanged: (value) =>
                  AppAppearance.setMode(value.first),
            ),
          ],
        ),
      ),
    );
  }
}
