/// Product capabilities mirror the device telemetry supported by this app.
/// Illustrations describe equipment categories, not a particular hardware model.
class ProductDefinition {
  const ProductDefinition({
    required this.type,
    required this.title,
    required this.summary,
    required this.features,
  });

  final String type;
  final String title;
  final String summary;
  final List<String> features;
}

class ProductCatalog {
  ProductCatalog._();

  static const products = <ProductDefinition>[
    ProductDefinition(
      type: 'gas_cylinder',
      title: 'Gas cylinder scale',
      summary: 'See how much gas remains before it runs out.',
      features: [
        'Remaining gas in kilograms and percent',
        'Cylinder capacity and empty-weight setup',
        'Personal alerts at the levels you choose',
      ],
    ),
    ProductDefinition(
      type: 'device7',
      title: 'Bottle vetting',
      summary: 'Keep bottle scans and verification activity together.',
      features: [
        'Bottle scan and verification results',
        'Four tray-weight readings and temperature',
        'Daily scan totals and verification history',
      ],
    ),
    ProductDefinition(
      type: 'device1',
      title: 'Refrigeration monitor',
      summary: 'Follow the condition of your cold-storage equipment.',
      features: [
        'Air, coil and drain temperatures',
        'Door activity and compressor readings',
        'Reading history and configurable alerts',
      ],
    ),
    ProductDefinition(
      type: 'device2',
      title: 'Multi-zone temperature',
      summary: 'Compare temperatures across your monitored zones.',
      features: [
        'Up to eight temperature zones',
        'Zone names and minimum / maximum readings',
        'Temperature history and personal alerts',
      ],
    ),
    ProductDefinition(
      type: 'device3',
      title: 'Ice machine monitor',
      summary: 'See your ice machine’s readings and operating activity.',
      features: [
        'Ice, air, high-side and low-side temperatures',
        'Water level and harvest activity',
        'Compressor readings and reporting history',
      ],
    ),
    ProductDefinition(
      type: 'device4',
      title: 'Multi-compressor monitor',
      summary: 'Compare current readings across your compressors.',
      features: [
        'Up to eight compressors with three phases each',
        'Per-compressor current and phase imbalance',
        'Power and energy estimates from reported readings',
      ],
    ),
    ProductDefinition(
      type: 'device5',
      title: 'Relay controller',
      summary: 'Keep track of your equipment’s relay states.',
      features: [
        'Status for up to sixteen relays',
        'On / off counts at a glance',
        'Relay duty-cycle and reporting history',
      ],
    ),
    ProductDefinition(
      type: 'device6',
      title: 'Pressure monitor',
      summary: 'Follow pressure readings across multiple sensors.',
      features: [
        'Up to eight pressure sensors',
        'Minimum, maximum and average readings',
        'Pressure history and configurable alerts',
      ],
    ),
  ];

  static ProductDefinition? byType(String type) {
    for (final product in products) {
      if (product.type == type) return product;
    }
    return null;
  }
}
