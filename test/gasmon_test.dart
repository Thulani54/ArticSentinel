import 'package:flutter_test/flutter_test.dart';
import 'package:artic_sentinel/gasmon/gas_core.dart';
import 'package:artic_sentinel/gasmon/gas_demo_data.dart';

GasReading r(int day, int hour, double kg) => GasReading(
      at: DateTime(2026, 9, day, hour),
      weightKg: kg,
    );

void main() {
  group('formulas', () {
    test('net gas subtracts tare, never negative', () {
      expect(netGasKg(currentKg: 30, tareKg: 11.5), closeTo(18.5, 1e-9));
      expect(netGasKg(currentKg: 5, tareKg: 11.5), 0);
    });

    test('level percent clamps to 0–100', () {
      final spec = GasSpec.forCapacity(14);
      expect(
          levelPercent(
              currentKg: spec.fullKg + 5, tareKg: spec.tareKg, fullKg: spec.fullKg),
          100);
      expect(
          levelPercent(currentKg: 0, tareKg: spec.tareKg, fullKg: spec.fullKg), 0);
      expect(
          levelPercent(
              currentKg: spec.tareKg + spec.capacityKg / 2,
              tareKg: spec.tareKg,
              fullKg: spec.fullKg),
          closeTo(50, 1e-9));
    });

    test('refill contributes zero consumption, never negative', () {
      expect(
          consumptionKg(previousKg: 20, currentKg: 32), 0); // refill +12 kg
      expect(consumptionKg(previousKg: 30, currentKg: 28.5), closeTo(1.5, 1e-9));
    });

    test('band thresholds: <20 low, <50 warning, else healthy', () {
      expect(bandFor(19.9), GasBand.low);
      expect(bandFor(20), GasBand.warning);
      expect(bandFor(49.9), GasBand.warning);
      expect(bandFor(50), GasBand.healthy);
    });
  });

  group('aggregations', () {
    test('dailySeries buckets by day and applies price', () {
      final series = dailySeries([
        r(1, 7, 30.0),
        r(2, 7, 29.0), // 1.0 kg on the 2nd
        r(3, 7, 27.5), // 1.5 kg on the 3rd
      ], pricePerKg: 30);
      expect(series.length, 2);
      expect(series[0].kg, closeTo(1.0, 1e-9));
      expect(series[0].cost, closeTo(30.0, 1e-9));
      expect(series[1].kg, closeTo(1.5, 1e-9));
    });

    test('offline gaps over 48h contribute nothing', () {
      final series = dailySeries([
        r(1, 7, 30.0),
        r(4, 9, 26.0), // 3 days later — monitor offline
        r(5, 9, 25.0),
      ], pricePerKg: 30);
      expect(series.length, 1);
      expect(series.single.day, DateTime(2026, 9, 5));
      expect(series.single.kg, closeTo(1.0, 1e-9));
    });

    test('todayUsage baseline is the last reading before today', () {
      final u = todayUsage([
        r(17, 19, 30.0),
        r(18, 6, 29.2),
        r(18, 12, 28.8),
      ], pricePerKg: 30, now: DateTime(2026, 9, 18, 15));
      expect(u.kg, closeTo(1.2, 1e-9));
      expect(u.cost, closeTo(36.0, 1e-9));
    });

    test('todayUsage with a refill overnight reads 0', () {
      final u = todayUsage([
        r(17, 19, 28.0),
        r(18, 6, 30.0),
        r(18, 12, 28.8),
      ], pricePerKg: 30, now: DateTime(2026, 9, 18, 15));
      expect(u.kg, 0);
    });
  });

  group('demo data', () {
    test('is deterministic, ascending and self-consistent', () {
      final now = DateTime(2026, 9, 20, 12);
      final d = generateGasDemoData(deviceKey: 'GAS-TEST-1', now: now);

      expect(d.readings, isNotEmpty);
      for (var i = 1; i < d.readings.length; i++) {
        expect(d.readings[i].at.isAfter(d.readings[i - 1].at), isTrue,
            reason: 'readings must ascend');
      }
      expect(d.currentLevelPct, greaterThan(0));
      expect(d.currentLevelPct, lessThanOrEqualTo(100));
      expect(d.currentNetKg, greaterThanOrEqualTo(0));

      // The story includes at least one refill and threshold/offline alerts.
      expect(d.alerts.any((a) => a.title == 'Cylinder refilled'), isTrue);
      expect(d.alerts, isNotEmpty);

      final again = generateGasDemoData(deviceKey: 'GAS-TEST-1', now: now);
      expect(again.readings.length, d.readings.length);
      expect(again.readings.last.weightKg,
          closeTo(d.readings.last.weightKg, 1e-9));
    });

    test('different devices get different stories', () {
      final now = DateTime(2026, 9, 20, 12);
      final a = generateGasDemoData(deviceKey: 'GAS-A', now: now);
      final b = generateGasDemoData(deviceKey: 'GAS-B', now: now);
      final differ = a.readings.length != b.readings.length ||
          (a.readings.last.weightKg - b.readings.last.weightKg).abs() > 1e-9;
      expect(differ, isTrue);
    });
  });

  group('alerts derivation', () {
    test('flags threshold crossings, refills and offline gaps', () {
      final spec = GasSpec.forCapacity(14);
      final alerts = deriveGasAlerts([
        r(1, 8, spec.fullKg), // 100%
        r(2, 8, spec.tareKg + spec.capacityKg * 0.4), // cross below 50%
        r(2, 20, spec.tareKg + spec.capacityKg * 0.15), // cross below 20%
        r(3, 8, spec.fullKg), // refill (also a 12h offline gap)
      ], spec: spec);
      final titles = alerts.map((a) => a.title).toSet();
      expect(titles, contains('Cylinder refilled'));
      expect(titles, contains(anyOf('Gas level below 20%', 'Monitor back online')));
    });
  });
}
