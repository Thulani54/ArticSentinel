import 'package:artic_sentinel/authentication/login.dart';
import 'package:artic_sentinel/authentication/signup_flow.dart';
import 'package:artic_sentinel/main.dart';
import 'package:artic_sentinel/onboarding/device_setup_wizard.dart';
import 'package:artic_sentinel/products/products_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> mount(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MyApp(initialRoute: path));
    await tester.pumpAndSettle();
  }

  testWidgets('direct setup link requires sign in', (tester) async {
    await mount(tester, '/device-setup?type=device7');
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(DeviceSetupWizard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public product link carries the selected type into signup',
      (tester) async {
    await mount(tester, '/products');
    expect(find.byType(ProductsPage), findsOneWidget);
    final link = find.text('I have this device — link it').first;
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.byType(SignUpFlowPage), findsOneWidget);
    expect(
        tester
            .widget<SignUpFlowPage>(find.byType(SignUpFlowPage))
            .initialDeviceType,
        'gas_cylinder');
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-in setup starts at the have-device question',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'ISLOGGEDIN': true,
      'AUTHTOKENKEY': 'test-only-token',
      'BUSINESSUIDKEY': 4,
    });
    await mount(tester, '/device-setup');
    expect(find.byType(DeviceSetupWizard), findsOneWidget);
    expect(find.text('Do you have a device to connect?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
