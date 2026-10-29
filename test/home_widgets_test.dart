import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewte/app.dart';
import 'package:jewte/platform/home_widgets.dart';
import 'package:jewte/screens/home_shell.dart';
import 'package:jewte/screens/home_widgets_screen.dart';
import 'package:jewte/state/study_store.dart';

import 'catalog_and_progress_test.dart' show testCatalog, MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'next concept follows the current subject and completed concepts advance',
    () async {
      final store = StudyStore(testCatalog(), MemoryRepository());
      final topics = store.catalog.forSubject('os');
      await store.visit(topics[4].id);
      expect(store.nextTopic.id, topics[4].id);
      await store.toggleDone(topics[4].id);
      expect(store.nextTopic.id, topics[5].id);
      await store.toggleSaved(topics[5].id);
      final snapshot = store.widgetSnapshot();
      expect(snapshot['completed'], 1);
      expect(snapshot['saved'], 1);
      expect(snapshot['nextQuery'], topics[5].title);
      expect(snapshot['nextId'], topics[5].id);
      expect(store.exportBackup(), contains(topics[4].id));
      store.dispose();
    },
  );

  testWidgets(
    'rapid tab changes preserve independent scroll positions and theme',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = StudyStore(testCatalog(), MemoryRepository());
      await tester.pumpWidget(JewteApp(store: store));
      await tester.pumpAndSettle();
      final shell = tester.state<HomeShellState>(find.byType(HomeShell));
      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme;
      await tester.drag(
        find.byKey(const PageStorageKey('home-tab-0')),
        const Offset(0, -320),
      );
      await tester.pumpAndSettle();
      final offset = shell.scrolls[0].offset;
      expect(offset, greaterThan(150));
      for (final tab in [1, 2, 3, 0, 2, 1, 0]) {
        await tester.tap(find.byKey(Key('nav-$tab')));
        await tester.pump(const Duration(milliseconds: 25));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(shell.scrolls[0].offset, offset);
      store.toggleDone(store.nextTopic.id);
      await tester.pumpAndSettle();
      expect(
        identical(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).theme,
          theme,
        ),
        isTrue,
      );
      expect(shell.scrolls[0].offset, offset);
      store.setReduceMotion(true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-2')));
      await tester.pump();
      expect(shell.fade.value, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await store.settled;
      store.dispose();
    },
  );

  testWidgets('widget gallery fits narrow screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 812);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = StudyStore(testCatalog(), MemoryRepository());
    await tester.pumpWidget(MaterialApp(home: HomeWidgetsScreen(store: store)));
    await tester.pumpAndSettle();
    expect(find.text('Your progress'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('pin-widget-topic')),
      250,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pin-widget-topic')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Long-press your home screen'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Android bridge coalesces progress, drains writes and consumes launch actions once',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('jewte.test/widgets');
      final calls = <MethodCall>[];
      Map<String, String>? destination = {'kind': 'topic', 'topicId': 'os-001'};
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        if (call.method == 'takeLaunchAction') {
          final result = destination;
          destination = null;
          return result;
        }
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.runAsync(() async {
        final bridge = HomeWidgetBridge(channel: channel)..initialize();
        final received = <WidgetDestination>[];
        final subscription = bridge.destinations.listen(received.add);
        bridge.scheduleSync({'completed': 1});
        bridge.scheduleSync({'completed': 2});
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await bridge.flush();
        expect(calls.where((c) => c.method == 'syncProgress').length, 1);
        expect(jsonDecode(calls.first.arguments as String)['completed'], 2);
        await bridge.takeLaunchAction();
        await bridge.takeLaunchAction();
        await Future<void>.delayed(Duration.zero);
        expect(received.length, 1);
        expect(received.single.topicId, 'os-001');
        await subscription.cancel();
        bridge.dispose();
      });
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
