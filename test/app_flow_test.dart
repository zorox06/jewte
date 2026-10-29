import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewte/app.dart';
import 'package:jewte/state/study_store.dart';

import 'catalog_and_progress_test.dart' show testCatalog, MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> fonts() async {
    for (final pair in [
      ('Manrope', 'assets/fonts/Manrope.ttf'),
      ('DMSerif', 'assets/fonts/DMSerifDisplay.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(pair.$1)..addFont(rootBundle.load(pair.$2));
      await loader.load();
    }
  }

  Future<StudyStore> app(
    WidgetTester tester, {
    Size size = const Size(412, 915),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = StudyStore(testCatalog(), MemoryRepository());
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('app-capture'),
        child: JewteApp(store: store),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('app-capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('docs/screenshots').createSync(recursive: true);
      File('docs/screenshots/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'subject completion and saving remain consistent across screens',
    (tester) async {
      final store = await app(tester);
      await tester.tap(find.byKey(const Key('nav-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('C Programming'));
      await tester.pumpAndSettle();
      final first = store.catalog.forSubject('c').first;
      expect(find.text(first.title), findsOneWidget);
      await tester.tap(find.byTooltip('Mark as completed').first);
      await tester.pumpAndSettle();
      expect(store.completed.contains(first.id), isTrue);
      await tester.tap(find.text(first.title));
      await tester.pumpAndSettle();
      expect(find.text('Completed · mark as remaining'), findsOneWidget);
      await tester.tap(find.byTooltip('Save topic'));
      await tester.pumpAndSettle();
      expect(store.saved.contains(first.id), isTrue);
      await tester.tap(find.byTooltip('Close topic'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back to library'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-3')));
      await tester.pumpAndSettle();
      expect(find.text(first.title), findsOneWidget);
      expect(find.byTooltip('Mark as remaining'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await store.settled;
    },
  );
  testWidgets(
    'search locates a niche topic and shows its source and YouTube action',
    (tester) async {
      await app(tester);
      await tester.tap(find.byKey(const Key('open-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('global-search-input')),
        'TLB reach',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('TLB reach = entry count times page size'),
        findsOneWidget,
      );
      await tester.tap(find.text('TLB reach = entry count times page size'));
      await tester.pumpAndSettle();
      expect(find.text('Search on YouTube'), findsOneWidget);
      expect(find.text('Supplied PYQ PDF · page 340'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('all tabs render at a narrow phone width with large text', (
    tester,
  ) async {
    await app(tester, size: const Size(320, 812), scale: 1.5);
    for (final index in [0, 1, 2, 3]) {
      await tester.tap(find.byKey(Key('nav-$index')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow on tab $index');
    }
  });
  testWidgets('capture real Flutter layouts in light and dark appearance', (
    tester,
  ) async {
    await tester.runAsync(fonts);
    final store = await app(tester);
    await screenshot(tester, '01-overview');
    await tester.tap(find.byKey(const Key('nav-1')));
    await tester.pumpAndSettle();
    await screenshot(tester, '02-subjects');
    await tester.tap(find.text('C Programming'));
    await tester.pumpAndSettle();
    await screenshot(tester, '03-checklist');
    await tester.tap(find.byTooltip('Back to library'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-2')));
    await tester.pumpAndSettle();
    await screenshot(tester, '04-niche');
    await tester.tap(find.text('Intermediate overflow before division'));
    await tester.pumpAndSettle();
    await screenshot(tester, '05-topic');
    await tester.tap(find.byTooltip('Close topic'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-0')));
    await tester.pumpAndSettle();
    store.setDark(true);
    await tester.pumpAndSettle();
    await screenshot(tester, '06-dark');
    expect(tester.takeException(), isNull);
  });
}
