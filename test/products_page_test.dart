import 'dart:convert';

import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/products/product_catalog.dart';
import 'package:artic_sentinel/products/product_enquiry_api.dart';
import 'package:artic_sentinel/products/products_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingApi extends ProductEnquiryApi {
  final requests = <ProductEnquiry>[];
  bool fail = false;

  @override
  Future<ProductEnquiryReceipt> submit(ProductEnquiry enquiry) async {
    requests.add(enquiry);
    if (fail) {
      throw const ProductEnquiryException('Connection interrupted. Try again.');
    }
    return const ProductEnquiryReceipt(reference: 'enquiry-reference');
  }
}

Future<void> _openForm(WidgetTester tester, _RecordingApi api,
    {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
    home: ProductsPage(enquiryApi: api),
  ));
  await tester.pumpAndSettle();
  await tester
      .ensureVisible(find.byKey(const ValueKey('request-gas_cylinder')));
  await tester.tap(find.byKey(const ValueKey('request-gas_cylinder')));
  await tester.pumpAndSettle();
}

Future<void> _completeForm(WidgetTester tester) async {
  for (final entry in {
    'name': 'Test Visitor',
    'email': 'visitor@example.com',
    'message': 'Please tell me about a gas scale for my kitchen.',
  }.entries) {
    final field = find.byKey(ValueKey('enquiry-${entry.key}'));
    await tester.ensureVisible(field);
    await tester.enterText(field, entry.value);
  }
  final consent = find.byKey(const ValueKey('enquiry-consent'));
  await tester.ensureVisible(consent);
  await tester.tap(consent);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Constants.authToken = '';
    Constants.myDisplayname = '';
    Constants.myEmail = '';
    Constants.cellphoneNumber = '';
    Constants.business_name = '';
  });

  test('catalogue covers every supported device type without duplicate entries',
      () {
    expect(ProductCatalog.products.map((product) => product.type).toSet(), {
      'gas_cylinder',
      for (var index = 1; index <= 7; index++) 'device$index',
    });
    expect(ProductCatalog.products, hasLength(8));
    expect(ProductCatalog.byType('unsupported'), isNull);
  });

  testWidgets('products remain readable at a narrow phone width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? chosenType;
    await tester.pumpWidget(MaterialApp(
        home: ProductsPage(onLinkDevice: (type) => chosenType = type)));
    await tester.pumpAndSettle();
    for (final product in ProductCatalog.products) {
      expect(find.text(product.title), findsOneWidget);
    }
    final link = find.text('I have this device — link it').first;
    await tester.ensureVisible(link);
    await tester.tap(link);
    expect(chosenType, 'gas_cylinder');
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone enquiry is full screen, validates before sending',
      (tester) async {
    final api = _RecordingApi();
    await _openForm(tester, api, size: const Size(320, 740));
    expect(tester.getSize(find.byType(Dialog)).width, 320);
    expect(tester.getSize(find.byType(Dialog)).height, 740);
    await tester.tap(find.byKey(const ValueKey('enquiry-submit')));
    await tester.pumpAndSettle();
    expect(api.requests, isEmpty);
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large-screen enquiry stays a bounded dialog', (tester) async {
    await _openForm(tester, _RecordingApi(), size: const Size(1024, 900));
    final formWidth =
        tester.getSize(find.byKey(const ValueKey('enquiry-name'))).width;
    expect(formWidth, lessThan(600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-in details prefill and success has a receipt',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'ISLOGGEDIN': true,
      'AUTHTOKENKEY': 'test-token',
      'USERNAMEKEY': 'Account Member',
      'USEREMAILKEY': 'member@example.com',
      'CELLPHONENUMBERKEY': '0123456789',
      'BUSINESSNAMEKEY': 'Example Kitchen',
    });
    final api = _RecordingApi();
    await _openForm(tester, api);
    expect(find.text('Account Member'), findsOneWidget);
    expect(find.text('member@example.com'), findsOneWidget);
    await _completeForm(tester);
    await tester.tap(find.byKey(const ValueKey('enquiry-submit')));
    await tester.pumpAndSettle();
    expect(api.requests, hasLength(1));
    expect(api.requests.single.productType, 'gas_cylinder');
    expect(api.requests.single.company, 'Example Kitchen');
    expect(find.text('Request received'), findsOneWidget);
    expect(find.text('enquiry-reference'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'public form does not expose a signed-out account’s stale details',
      (tester) async {
    Constants.authToken = 'stale-token';
    Constants.myDisplayname = 'Previous Account';
    Constants.myEmail = 'previous@example.com';
    await _openForm(tester, _RecordingApi());
    expect(find.text('Previous Account'), findsNothing);
    expect(find.text('previous@example.com'), findsNothing);
  });

  testWidgets('failed requests retain data and retry with the same identifier',
      (tester) async {
    final api = _RecordingApi()..fail = true;
    await _openForm(tester, api);
    await _completeForm(tester);
    await tester.tap(find.byKey(const ValueKey('enquiry-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Request received'), findsNothing);
    expect(find.text('Connection interrupted. Try again.'), findsOneWidget);
    expect(find.text('Test Visitor'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.byKey(const ValueKey('enquiry-submit')));
    await tester.pumpAndSettle();
    expect(api.requests, hasLength(2));
    expect(api.requests[1].requestId, api.requests[0].requestId);
    expect(find.text('Request received'), findsOneWidget);
  });

  testWidgets('editing an unconfirmed request gets a new submission identifier',
      (tester) async {
    final api = _RecordingApi()..fail = true;
    await _openForm(tester, api);
    await _completeForm(tester);
    await tester.tap(find.byKey(const ValueKey('enquiry-submit')));
    await tester.pumpAndSettle();
    final message = find.byKey(const ValueKey('enquiry-message'));
    await tester.ensureVisible(message);
    await tester.enterText(message, 'Please advise on two gas scales instead.');
    api.fail = false;
    await tester.tap(find.byKey(const ValueKey('enquiry-submit')));
    await tester.pumpAndSettle();
    expect(api.requests, hasLength(2));
    expect(api.requests[1].requestId, isNot(api.requests[0].requestId));
  });

  const enquiry = ProductEnquiry(
    requestId: '676dc6f5-ab30-4f59-8066-58866edca719',
    name: 'Visitor',
    email: 'visitor@example.com',
    productType: 'device7',
    message: 'I would like bottle vetting information.',
  );

  test('public enquiry sends only explicit contact and selected product data',
      () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/products/enquiries/');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(request.body), enquiry.toJson());
      return http.Response(
          '{"success":true,"reference":"receipt","delivery_status":"queued"}',
          201);
    });
    final receipt = await ProductEnquiryApi(client: client).submit(enquiry);
    expect(receipt.reference, 'receipt');
  });

  for (final response in [
    http.Response('<html>Proxy error</html>', 200),
    http.Response('{"success":true}', 201),
    http.Response('{"success":false,"reference":"not-saved"}', 200),
    http.Response('Unavailable', 503),
  ]) {
    test(
        'unconfirmed response ${response.statusCode} does not report success '
        '${response.body}', () async {
      final api = ProductEnquiryApi(client: MockClient((_) async => response));
      await expectLater(
          api.submit(enquiry), throwsA(isA<ProductEnquiryException>()));
    });
  }

  test('rate-limited enquiry gives a retry instruction', () async {
    final api = ProductEnquiryApi(
        client: MockClient((_) async => http.Response('{}', 429)));
    await expectLater(
        api.submit(enquiry),
        throwsA(isA<ProductEnquiryException>().having((error) => error.message,
            'message', contains('Wait a few minutes'))));
  });
}
