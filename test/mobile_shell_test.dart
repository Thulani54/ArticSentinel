import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/gasmon/gas_theme.dart';
import 'package:artic_sentinel/layouts/main_layout.dart';
import 'package:artic_sentinel/widgets/mobile_forms.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:artic_sentinel/widgets/mobile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

GoRouter _testRouter() => GoRouter(
      initialLocation: '/dashboard-home',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainLayout(
            currentRoute: state.uri.path,
            child: child,
          ),
          routes: [
            for (final route in [
              '/dashboard-home',
              '/device-management',
              '/alerts',
              '/settings',
              '/settings/security',
              '/help',
            ])
              GoRoute(
                path: route,
                builder: (context, state) => Center(
                  child: Text('Page ${state.uri.path}'),
                ),
              ),
          ],
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Text('Login'),
        ),
      ],
    );

void _setViewport(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<Finder> _openDrawerItem(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Open navigation'));
  await tester.pumpAndSettle();
  final item = find.widgetWithText(ListTile, label);
  final scrollable = find.descendant(
    of: find.byType(Drawer),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(item, 160, scrollable: scrollable.first);
  await tester.pumpAndSettle();
  return item;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalBusiness = Constants.business_name;
  final originalDisplayName = Constants.myDisplayname;
  final originalFontFetching = GoogleFonts.config.allowRuntimeFetching;

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Constants.business_name =
        'Artic Sentinel refrigeration operations workspace';
    Constants.myDisplayname = 'Thulani Moyo';
  });
  tearDown(() {
    Constants.business_name = originalBusiness;
    Constants.myDisplayname = originalDisplayName;
    GoogleFonts.config.allowRuntimeFetching = originalFontFetching;
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('phone drawer navigates and selects the correct item at $width',
        (tester) async {
      _setViewport(tester, width);
      final router = _testRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: articMobileTheme(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final destination in {
        'Notifications': '/alerts',
        'Settings': '/settings',
        'Help & Support': '/help',
      }.entries) {
        final item = await _openDrawerItem(tester, destination.key);
        expect(tester.takeException(), isNull);
        await tester.tap(item);
        await tester.pumpAndSettle();
        expect(
            router.routeInformationProvider.value.uri.path, destination.value);
        expect(find.text('Page ${destination.value}'), findsOneWidget);
        expect(tester.state<ScaffoldState>(find.byType(Scaffold)).isDrawerOpen,
            isFalse);

        final selectedItem = await _openDrawerItem(tester, destination.key);
        expect(tester.widget<ListTile>(selectedItem).selected, isTrue);
        expect(
          tester
              .widgetList<ListTile>(find.byType(ListTile))
              .where((tile) => tile.selected),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Close navigation'));
        await tester.pumpAndSettle();
      }

      router.go('/settings/security');
      await tester.pumpAndSettle();
      final settings = await _openDrawerItem(tester, 'Settings');
      expect(tester.widget<ListTile>(settings).selected, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final width in [320.0, 430.0]) {
    testWidgets('phone shortcuts keep every destination reachable at $width',
        (tester) async {
      _setViewport(tester, width);
      final router = _testRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
          MaterialApp.router(theme: articMobileTheme(), routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.byIcon(Iconsax.more), findsOneWidget);
      final navigation = tester.widget<ClipRRect>(
          find.byKey(const ValueKey('mobile-navigation-surface')));
      expect(navigation.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(20)));
      for (final icon in [
        Iconsax.home_2,
        Iconsax.category,
        Iconsax.notification,
        Iconsax.setting_2
      ]) {
        expect(
            find.descendant(
                of: find.byKey(const ValueKey('mobile-navigation-surface')),
                matching: find.byIcon(icon)),
            findsOneWidget);
      }
      for (final destination in {
        'Equipment': '/device-management',
        'Alerts': '/alerts',
        'Settings': '/settings',
        'Home': '/dashboard-home',
      }.entries) {
        final button = find.byKey(ValueKey('mobile-nav-${destination.key}'));
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(
            router.routeInformationProvider.value.uri.path, destination.value);
        expect(tester.getRect(button).right, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('phone headings wrap with large text and an action',
      (tester) async {
    _setViewport(tester, 320);
    await tester.pumpWidget(MaterialApp(
      theme: articMobileTheme(),
      home: MediaQuery(
        data: const MediaQueryData(
            size: Size(320, 800), textScaler: TextScaler.linear(1.5)),
        child: Scaffold(
            body: MobileScreenHeader(
          title: 'Equipment performance',
          description: 'Review the latest readings from your equipment.',
          trailing:
              IconButton(onPressed: () {}, icon: const Icon(Icons.refresh)),
        )),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Equipment performance'), findsOneWidget);
  });

  testWidgets('tablet shell keeps its header and sidebar within 800 pixels',
      (tester) async {
    _setViewport(tester, 800);
    final router = _testRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: articMobileTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Page /dashboard-home'), findsOneWidget);
    final header = tester.getRect(find.byType(AppBar));
    expect(header.left, greaterThanOrEqualTo(0));
    expect(header.right, lessThanOrEqualTo(800));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final width in [320.0, 430.0, 800.0]) {
    testWidgets('form row with Spacer works inside a scroll view at $width',
        (tester) async {
      _setViewport(tester, width);
      await tester.pumpWidget(MaterialApp(
        theme: articMobileTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MobileFormRow(children: [
              OutlinedButton(
                key: const Key('cancel-action'),
                onPressed: () {},
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('save-action'),
                onPressed: () {},
                child: const Text('Save changes'),
              ),
            ]),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final cancel = tester.getRect(find.byKey(const Key('cancel-action')));
      final save = tester.getRect(find.byKey(const Key('save-action')));
      expect(save.height, greaterThanOrEqualTo(48));
      expect(save.right, lessThanOrEqualTo(width - 16));
      if (width < 600) {
        expect(save.top, greaterThanOrEqualTo(cancel.bottom + 16));
        expect(save.width, width - 32);
      } else {
        expect(save.top, cancel.top);
        expect(save.left, greaterThan(cancel.right));
      }
      final context = tester.element(find.byKey(const Key('save-action')));
      expect(Theme.of(context).colorScheme.primary, GasPalette.primary);
      expect(Theme.of(context).scaffoldBackgroundColor, GasPalette.page);
      expect(tester.takeException(), isNull);
    });
  }
}
