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
              currentKg: spec.fullKg + 5,
              tareKg: spec.tareKg,
              fullKg: spec.fullKg),
          100);
      expect(
          levelPercent(currentKg: 0, tareKg: spec.tareKg, fullKg: spec.fullKg),
          0);
      expect(
          levelPercent(
              currentKg: spec.tareKg + spec.capacityKg / 2,
              tareKg: spec.tareKg,
              fullKg: spec.fullKg),
          closeTo(50, 1e-9));
    });

    test('refill contributes zero consumption, never negative', () {
      expect(consumptionKg(previousKg: 20, currentKg: 32), 0); // refill +12 kg
      expect(
          consumptionKg(previousKg: 30, currentKg: 28.5), closeTo(1.5, 1e-9));
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

    test('todayUsage counts consumption after an overnight refill', () {
      final u = todayUsage([
        r(17, 19, 28.0),
        r(18, 6, 30.0),
        r(18, 12, 28.8),
      ], pricePerKg: 30, now: DateTime(2026, 9, 18, 15));
      expect(u.kg, closeTo(1.2, 1e-9));
      expect(u.cost, closeTo(36, 1e-9));
    });

    test('report and today cancel small rises instead of counting every dip',
        () {
      final readings = [
        r(17, 23, 79.307),
        r(18, 6, 78.8),
        r(18, 9, 79.4279),
        r(18, 12, 79),
      ];
      final report = dailySeries(readings, pricePerKg: 39).single;
      final today = todayUsage(readings.reversed.toList(),
          pricePerKg: 39, now: DateTime(2026, 9, 18, 15));
      expect(today.kg, closeTo(report.kg, 1e-9));
      expect(today.cost, closeTo(report.cost, 1e-9));
      // Summing drops used to report 0.9349 kg / R36.46 for these readings.
      expect(today.kg, closeTo(0.307, 1e-9));
      expect(today.kg.toStringAsFixed(2), '0.31');
      expect(money(today.cost), 'R11.97');
    });

    test('repeated fluctuations with no net loss create no consumption', () {
      final series = dailySeries([
        r(17, 23, 30),
        r(18, 1, 29.8),
        r(18, 2, 30.1),
        r(18, 3, 29.9),
        r(18, 4, 30),
      ], pricePerKg: 39);
      expect(series.single.kg, 0);
      expect(series.single.cost, 0);
    });

    test('consumption before and after a detected refill is preserved', () {
      final series = dailySeries([
        r(17, 23, 10),
        r(18, 6, 9),
        r(18, 9, 20),
        r(18, 12, 19.5),
      ], pricePerKg: 39);
      expect(series.single.kg, closeTo(1.5, 1e-9));
      expect(series.single.cost, closeTo(58.5, 1e-9));
    });

    test('November 8 hourly readings do not inflate 0.335 kg to 0.984 kg', () {
      final weights = [
        36.354,
        36.384,
        36.386,
        36.370,
        36.390,
        36.358,
        36.391,
        36.376,
        36.375,
        36.371,
        36.378,
        36.369,
        36.386,
        36.127,
        36.579,
        36.303,
        36.388,
        36.296,
        36.277,
        36.280,
        36.087,
        36.022
      ];
      final readings = [
        GasReading(at: DateTime(2026, 11, 7, 23), weightKg: 36.357),
        for (var hour = 0; hour < weights.length; hour++)
          GasReading(at: DateTime(2026, 11, 8, hour), weightKg: weights[hour]),
      ];
      final report = dailySeries(readings, pricePerKg: 39).single;
      final today =
          todayUsage(readings, pricePerKg: 39, now: DateTime(2026, 11, 8, 22));
      expect(report.kg, closeTo(0.335, 1e-9));
      expect(today.kg, closeTo(report.kg, 1e-9));
      expect(today.cost, closeTo(report.cost, 1e-9));
    });

    test('today usage ignores future data and old offline gaps', () {
      final readings = [
        r(14, 23, 40),
        r(18, 6, 30), // Missing days are not attributed to today.
        r(18, 12, 29.5),
        r(18, 18, 27), // After now: must not count.
        r(19, 6, 25),
      ];
      final today =
          todayUsage(readings, pricePerKg: 39, now: DateTime(2026, 9, 18, 15));
      expect(today.kg, closeTo(0.5, 1e-9));
      expect(today.cost, closeTo(19.5, 1e-9));
    });

    test('empty, single and stale readings have no usage today', () {
      for (final readings in <List<GasReading>>[
        [],
        [r(18, 6, 30)],
        [r(16, 6, 30), r(17, 6, 29)],
      ]) {
        final today = todayUsage(readings,
            pricePerKg: 39, now: DateTime(2026, 9, 18, 15));
        expect(today.kg, 0);
        expect(today.cost, 0);
      }
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
      expect(titles,
          contains(anyOf('Gas level below 20%', 'Monitor back online')));
    });
  });
}
