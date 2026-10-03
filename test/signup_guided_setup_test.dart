import 'dart:convert';

import 'package:artic_sentinel/authentication/signup_flow.dart';
import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/services/auth_session.dart';
import 'package:artic_sentinel/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('sign-out clears the session used by public product forms and setup',
      () async {
    SharedPreferences.setMockInitialValues({
      Sharedprefs.sharedPreferenceUserLoggedInKey: true,
      Sharedprefs.sharedPreferenceAuthTokenKey: 'test-only-token',
      Sharedprefs.sharedPasswordPrefKey: 'test-only-password',
      Sharedprefs.sharedPreferenceUserEmailKey: 'customer@example.test',
      Sharedprefs.sharedPreferenceBusinessUidKey: 4,
      'seen_welcome_v1': true,
    });
    Constants.authToken = 'test-only-token';
    Constants.myEmail = 'customer@example.test';
    Constants.myDisplayname = 'Example Customer';
    await AuthSession.signOut();
    expect(await Sharedprefs.getUserLoggedInSharedPreference(), isFalse);
    expect(await Sharedprefs.getAuthTokenPreference(), isNull);
    expect(await Sharedprefs.getBusinessUidSharedPreference(), isNull);
    expect(Constants.myEmail, isEmpty);
    expect(Constants.authToken, isEmpty);
    expect((await SharedPreferences.getInstance()).getBool('seen_welcome_v1'),
        isTrue);
  });

  Future<GoRouter> mount(WidgetTester tester, http.Client client,
      {String? initialType,
      ValueChanged<Map<String, dynamic>>? onSession}) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(initialLocation: '/signup', routes: [
      GoRoute(
          path: '/signup',
          builder: (_, __) => SignUpFlowPage(
                client: client,
                initialDeviceType: initialType,
                applySession: (body, _) async => onSession?.call(body),
              )),
      GoRoute(
          path: '/device-setup',
          builder: (_, __) => const Text('Guided setup')),
      GoRoute(
          path: '/products',
          builder: (_, __) => const Text('Product catalogue')),
      GoRoute(path: '/login', builder: (_, __) => const Text('Sign in')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label);

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> fillAccount(WidgetTester tester) async {
    await tap(tester, 'Just me');
    await tap(tester, 'Continue');
    final first = tester.getRect(field('First name'));
    final last = tester.getRect(field('Last name'));
    expect(last.top, greaterThanOrEqualTo(first.bottom));
    await tester.enterText(field('First name'), 'Example');
    await tester.enterText(field('Last name'), 'Customer');
    await tester.enterText(field('Email'), 'customer@example.test');
    await tap(tester, 'Continue');
    await tester.enterText(field('Password'), 'local-test-password');
    await tester.enterText(field('Confirm password'), 'local-test-password');
  }

  final loginBody = {
    'token': 'test-only-token',
    'user': {'email': 'customer@example.test'},
  };

  testWidgets('account is authenticated before type-specific setup starts',
      (tester) async {
    final paths = <String>[];
    var applied = false;
    final client = MockClient((request) async {
      paths.add(request.url.path);
      return request.url.path.endsWith('signup/v2/')
          ? http.Response('{}', 201)
          : http.Response(jsonEncode(loginBody), 200);
    });
    final router = await mount(tester, client,
        initialType: 'gas_cylinder', onSession: (_) => applied = true);
    await fillAccount(tester);
    expect(paths, isEmpty);
    await tap(tester, 'Create account');
    expect(applied, isTrue);
    expect(paths, ['/api/signup/v2/', '/api/login/']);
    expect(router.routeInformationProvider.value.uri.path, '/device-setup');
    expect(router.routeInformationProvider.value.uri.queryParameters['type'],
        'gas_cylinder');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed auto-login retries without registering the account twice',
      (tester) async {
    var registrations = 0;
    var signIns = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('signup/v2/')) {
        registrations++;
        return http.Response('{}', 201);
      }
      signIns++;
      return signIns == 1
          ? http.Response('unavailable', 503)
          : http.Response(jsonEncode(loginBody), 200);
    });
    final router = await mount(tester, client);
    await fillAccount(tester);
    await tap(tester, 'Create account');
    expect(find.textContaining('Your account was created.'), findsOneWidget);
    await tap(tester, 'Sign in and connect devices');
    expect(registrations, 1);
    expect(signIns, 2);
    expect(router.routeInformationProvider.value.uri.path, '/device-setup');
  });

  testWidgets('failed signup stays editable and never creates a device',
      (tester) async {
    final paths = <String>[];
    final router = await mount(tester, MockClient((request) async {
      paths.add(request.url.path);
      return http.Response(jsonEncode({'error': 'Email already exists.'}), 400);
    }));
    await fillAccount(tester);
    await tap(tester, 'Create account');
    expect(router.routeInformationProvider.value.uri.path, '/signup');
    expect(paths, ['/api/signup/v2/']);
    expect(find.text('Email already exists.'), findsOneWidget);
    expect(tester.widget<TextField>(field('Email')).enabled, isTrue);
  });

  testWidgets('products can be explored before creating an account',
      (tester) async {
    await mount(tester,
        MockClient((_) async => throw StateError('No API request expected')));
    await tap(tester, 'Explore our products');
    expect(find.text('Product catalogue'), findsOneWidget);
  });
}
