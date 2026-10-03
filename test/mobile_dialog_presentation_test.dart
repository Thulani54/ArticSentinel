import 'package:artic_sentinel/widgets/mobile_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 430.0, 600.0, 800.0]) {
    for (final alert in [false, true]) {
      testWidgets(
          'dialog fills phones and respects safe controls at $width; alert=$alert',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? result;
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 44, bottom: 34),
              viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
              textScaler: const TextScaler.linear(1.4),
            ),
            child: child!,
          ),
          home: Builder(
              builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () async {
                        result = await showMobileDialog<String>(
                          context: context,
                          builder: (context) {
                            final close = TextButton(
                              key: const Key('dialog-close'),
                              onPressed: () =>
                                  Navigator.of(context).pop('saved'),
                              child: const Text('Done'),
                            );
                            return alert
                                ? MobileAlertDialog(
                                    title: const Text('Device information'),
                                    content: const Text(
                                        'A readable device message.'),
                                    actions: [close],
                                  )
                                : MobileDialog(
                                    child: SizedBox(
                                      key: const Key('dialog-content'),
                                      width: 300,
                                      height: 200,
                                      child: Column(children: [
                                        const Text('Device information'),
                                        const Spacer(),
                                        close,
                                      ]),
                                    ),
                                  );
                          },
                        );
                      },
                      child: const Text('Open'),
                    ),
                  )),
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final surface = find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first;
        final bounds = tester.getRect(surface);
        if (width < 600) {
          expect(bounds, Rect.fromLTWH(0, 0, width, 800));
          expect(tester.widget<Material>(surface).color, Colors.white);
        } else {
          expect(bounds.left, greaterThan(0));
          expect(bounds.top, greaterThanOrEqualTo(44));
          expect(bounds.bottom, lessThanOrEqualTo(766));
        }
        final closeBounds =
            tester.getRect(find.byKey(const Key('dialog-close')));
        expect(closeBounds.top, greaterThanOrEqualTo(44));
        expect(closeBounds.bottom, lessThanOrEqualTo(766));
        await tester.tap(find.byKey(const Key('dialog-close')));
        await tester.pumpAndSettle();
        expect(result, 'saved');
        expect(find.byType(Dialog), findsNothing);
      });
    }
  }
}
