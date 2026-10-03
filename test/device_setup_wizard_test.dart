import 'dart:async';
import 'dart:convert';
import 'package:artic_sentinel/gasmon/gas_api.dart';
import 'package:artic_sentinel/models/device.dart';
import 'package:artic_sentinel/onboarding/device_setup_wizard.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const config = GasConfig(
    gasCapacityKg: 9,
    tareKg: 7.6,
    pricePerKg: 0,
    lowPct: 20,
    warningPct: 40,
    isDefault: false);
Device gas({int? id}) => Device(
    id: id,
    name: 'Kitchen gas',
    deviceId: 'SCALE-42',
    deviceType: 'gas_cylinder');
http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

class FakeSetup extends DeviceSetupService {
  int saves = 0;
  int checks = 0;
  Device? draft;
  GasConfig? setup;
  bool received = false;
  @override
  Future<DeviceSetupResult> register(
      {required Device draft, GasConfig? gasConfig}) async {
    saves++;
    this.draft = draft;
    setup = gasConfig;
    return DeviceSetupResult(Device(
        id: 42,
        name: draft.name,
        deviceId: draft.deviceId,
        deviceType: draft.deviceType));
  }

  @override
  Future<bool> hasReading(Device device) async {
    checks++;
    return received;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues(
        {'BUSINESSUIDKEY': 12, 'AUTHTOKENKEY': 'test-only-token'});
  });

  test('creates only device-specific fields and stores entered cylinder values',
      () async {
    final requests = <http.Request>[];
    final service = DeviceSetupService(client: MockClient((request) async {
      requests.add(request);
      expect(request.headers['Authorization'], 'Token test-only-token');
      return switch (request.url.path) {
        '/api/devices/list/' => json({'devices': []}),
        '/api/devices/create/' => json({'device': gas(id: 42).toJson()}, 201),
        '/api/gas/readings/' => json({
            'config': {...config.toJson(), 'is_default': true}
          }),
        '/api/gas/config/update/' => json({
            'config': {...config.toJson(), 'is_default': false}
          }),
        _ => throw StateError(request.url.path),
      };
    }));
    final result = await service.register(draft: gas(), gasConfig: config);
    expect(result.device.id, 42);
    final create = jsonDecode(requests[1].body) as Map;
    expect(create['device_type'], 'gas_cylinder');
    expect(create.containsKey('phase_type'), isFalse);
    expect(create.containsKey('target_temp_min'), isFalse);
    final setup = jsonDecode(requests.last.body) as Map;
    expect(setup['gas_capacity_kg'], 9);
    expect(setup['tare_kg'], 7.6);
  });

  test(
      'existing devices keep their cylinder settings and are not created twice',
      () async {
    final paths = <String>[];
    final service = DeviceSetupService(client: MockClient((request) async {
      paths.add(request.url.path);
      return json({
        'devices': [gas(id: 42).toJson()]
      });
    }));
    final result = await service.register(draft: gas(), gasConfig: config);
    expect(result.alreadyRegistered, isTrue);
    expect(paths, ['/api/devices/list/']);
  });

  test('retry after cylinder config failure does not create another device',
      () async {
    int creates = 0, updates = 0;
    final service = DeviceSetupService(
        client: MockClient((request) async => switch (request.url.path) {
              '/api/devices/list/' => json({'devices': []}),
              '/api/devices/create/' =>
                (creates++, json({'device': gas(id: 42).toJson()}, 201)).$2,
              '/api/gas/readings/' => json({
                  'config': {...config.toJson(), 'is_default': true}
                }),
              '/api/gas/config/update/' => json({
                  'config': {...config.toJson(), 'is_default': false}
                }, ++updates == 1 ? 503 : 200),
              _ => throw StateError(request.url.path),
            }));
    await expectLater(service.register(draft: gas(), gasConfig: config),
        throwsA(isA<DeviceSetupException>()));
    await service.register(draft: gas(), gasConfig: config);
    expect(creates, 1);
    expect(updates, 2);
  });

  test('lost create response is reconciled before retrying', () async {
    int creates = 0, updates = 0;
    final service = DeviceSetupService(client: MockClient((request) async {
      switch (request.url.path) {
        case '/api/devices/list/':
          return json({
            'devices': creates == 0 ? [] : [gas(id: 42).toJson()]
          });
        case '/api/devices/create/':
          creates++;
          throw TimeoutException('lost reply');
        case '/api/gas/readings/':
          return json({
            'config': {...config.toJson(), 'is_default': true}
          });
        case '/api/gas/config/update/':
          updates++;
          return json({
            'config': {...config.toJson(), 'is_default': false}
          });
        default:
          throw StateError(request.url.path);
      }
    }));
    await expectLater(service.register(draft: gas(), gasConfig: config),
        throwsA(isA<DeviceSetupException>()));
    final recovered = await service.register(draft: gas(), gasConfig: config);
    expect(recovered.device.id, 42);
    expect(creates, 1);
    expect(updates, 1);
  });

  test('recovered custom gas setup is never overwritten', () async {
    int creates = 0;
    final paths = <String>[];
    final service = DeviceSetupService(client: MockClient((request) async {
      paths.add(request.url.path);
      switch (request.url.path) {
        case '/api/devices/list/':
          return json({
            'devices': creates == 0 ? [] : [gas(id: 42).toJson()]
          });
        case '/api/devices/create/':
          creates++;
          throw TimeoutException('lost reply');
        case '/api/gas/readings/':
          return json({
            'config': {...config.toJson(), 'is_default': false}
          });
        default:
          throw StateError(request.url.path);
      }
    }));
    await expectLater(service.register(draft: gas(), gasConfig: config),
        throwsA(isA<DeviceSetupException>()));
    await service.register(draft: gas(), gasConfig: config);
    expect(paths, isNot(contains('/api/gas/config/update/')));
  });

  test('failed inventory blocks create and missing login blocks every request',
      () async {
    var requests = 0;
    final service = DeviceSetupService(client: MockClient((request) async {
      requests++;
      return json({}, 503);
    }));
    await expectLater(service.register(draft: gas(), gasConfig: config),
        throwsA(isA<DeviceSetupException>()));
    expect(requests, 1);
    SharedPreferences.setMockInitialValues({});
    await expectLater(service.register(draft: gas(), gasConfig: config),
        throwsA(isA<DeviceSetupException>()));
    expect(requests, 1);
  });

  test('reading status ignores metadata and readings from other devices',
      () async {
    var data = <Object>[
      {
        'device_id': 'OTHER',
        'time': DateTime.now().toUtc().toIso8601String(),
        'tray1wt': 2
      },
      {
        'device_id': 'BOTTLE-1',
        'time': DateTime.now().toUtc().toIso8601String(),
        'custom_labels': {'tray': 'one'},
        'is_online': true
      }
    ];
    final service =
        DeviceSetupService(client: MockClient((_) async => json(data)));
    final bottle = Device(
        id: 8, name: 'Bottle', deviceId: 'BOTTLE-1', deviceType: 'device7');
    expect(await service.hasReading(bottle), isFalse);
    data = [
      {
        'device_id': 'BOTTLE-1',
        'time': DateTime.now().toUtc().toIso8601String(),
        'tray1wt': 0
      }
    ];
    expect(await service.hasReading(bottle), isTrue);
  });

  test('old readings do not confirm a current connection', () async {
    final service = DeviceSetupService(
        client: MockClient((_) async => json({
              'latest': {
                'time': DateTime.now()
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
                'gross_kg': 12.0
              },
            })));
    expect(await service.hasReading(gas(id: 42)), isFalse);
  });

  test('successful HTTP status without saved config does not finish setup',
      () async {
    final service = DeviceSetupService(
        client: MockClient((request) async => switch (request.url.path) {
              '/api/devices/list/' => json({'devices': []}),
              '/api/devices/create/' =>
                json({'device': gas(id: 42).toJson()}, 201),
              '/api/gas/readings/' => json({
                  'config': {...config.toJson(), 'is_default': true}
                }),
              '/api/gas/config/update/' => json({'ok': true}),
              _ => throw StateError(request.url.path),
            }));
    await expectLater(service.register(draft: gas(), gasConfig: config),
        throwsA(isA<DeviceSetupException>()));
  });

  Future<void> mount(WidgetTester t, Widget child,
      {double width = 360, double scale = 1, bool reduced = true}) async {
    t.view.physicalSize = Size(width, 820);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
        theme: articMobileTheme(),
        home: MediaQuery(
            data: MediaQueryData(
                size: Size(width, 820),
                textScaler: TextScaler.linear(scale),
                disableAnimations: reduced),
            child: child)));
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String label) async {
    final finder = find.text(label).last;
    await t.ensureVisible(finder);
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  Future<void> identity(WidgetTester t) async {
    await t.enterText(find.byType(TextFormField).at(0), 'SCALE-42');
    await t.enterText(find.byType(TextFormField).at(1), 'Kitchen gas');
    await tap(t, 'Continue');
  }

  testWidgets('welcome supports browse and skip without writes', (t) async {
    int browse = 0, done = 0;
    final service = FakeSetup();
    await mount(
        t,
        DeviceSetupWizard(
            service: service,
            onBrowseProducts: () => browse++,
            onDone: () => done++),
        width: 320,
        scale: 1.3);
    expect(find.text('Do you have a device to connect?'), findsOneWidget);
    await tap(t, 'Explore our products');
    await tap(t, 'Explore my workspace first');
    expect(browse, 1);
    expect(done, 1);
    expect(service.saves, 0);
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'gas guide validates weights and opens Bluetooth after registration',
      (t) async {
    final service = FakeSetup();
    Device? connected;
    await mount(
        t,
        DeviceSetupWizard(
            initialDeviceType: 'gas_cylinder',
            service: service,
            scaleSetupBuilder: (device) {
              connected = device;
              return const Scaffold(body: Text('Bluetooth setup'));
            }),
        reduced: false);
    await identity(t);
    expect(find.text('Set your cylinder size'), findsOneWidget);
    await tap(t, 'Continue');
    expect(find.text('Step 2 of 3'), findsOneWidget);
    await tap(t, '9 kg');
    await t.enterText(find.byType(TextFormField).at(1), '7.6');
    await tap(t, 'Continue');
    expect(find.text('Step 3 of 3'), findsOneWidget);
    await tap(t, 'Link device');
    expect(service.saves, 1);
    expect(service.setup!.gasCapacityKg, 9);
    expect(service.setup!.tareKg, 7.6);
    expect(find.text('Waiting for a fresh reading'), findsOneWidget);
    expect(find.text('Your device is reporting'), findsNothing);
    await tap(t, 'Connect scale to Wi-Fi');
    expect(connected!.id, 42);
    expect(find.text('Bluetooth setup'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Continue scrolls the missing tare field above the fixed footer',
      (t) async {
    await mount(
        t,
        DeviceSetupWizard(
            initialDeviceType: 'gas_cylinder', service: FakeSetup()),
        width: 390);
    await identity(t);
    await tap(t, '9 kg');
    await tap(t, 'Continue');
    expect(find.text('Step 2 of 3'), findsOneWidget);
    final tare = find.byType(TextFormField).at(1);
    expect(t.getRect(tare).bottom,
        lessThan(t.getTopLeft(find.byType(FilledButton)).dy));
    expect(t.getRect(tare).top, greaterThan(0));
    expect(find.text('Enter the empty cylinder weight (kg).'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('bottle guide explains actual network setup without gas fields',
      (t) async {
    final service = FakeSetup();
    await mount(
        t, DeviceSetupWizard(initialDeviceType: 'device7', service: service),
        width: 320, scale: 1.3);
    await identity(t);
    expect(find.text('Give it power and a connection'), findsOneWidget);
    expect(find.text('Gas capacity (kg)'), findsNothing);
    await tap(t, 'Continue');
    await tap(t, 'Link device');
    expect(service.draft!.deviceType, 'device7');
    expect(service.setup, isNull);
    expect(find.text('Connect scale to Wi-Fi'), findsNothing);
    expect(find.text('Waiting for a fresh reading'), findsOneWidget);
    service.received = true;
    await tap(t, 'Check for a reading');
    expect(find.text('Your device is reporting'), findsOneWidget);
    await tap(t, 'Connect another device');
    expect(find.text('What are you connecting?'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('type choice fits phone and tablet with reduced motion',
      (t) async {
    await mount(t, DeviceSetupWizard(service: FakeSetup()),
        width: 760, scale: 1.3);
    await tap(t, 'Yes, I have a device');
    expect(find.text('What are you connecting?'), findsOneWidget);
    await tap(t, 'Bottle vetting');
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
