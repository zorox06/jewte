import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jewte/app.dart';
import 'package:jewte/models/catalog.dart';
import 'package:jewte/platform/home_widgets.dart';
import 'package:jewte/screens/home_widgets_screen.dart';
import 'package:jewte/state/study_store.dart';

class EphemeralProgress implements ProgressRepository {
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String value) async {
    data = value;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native widgets render, persist progress and keep exact topic searches',
    (tester) async {
      const channel = MethodChannel('app.jewte/widgets');
      final bridge = HomeWidgetBridge()..initialize();
      final catalog = await Catalog.load();
      final previous = await bridge.info();
      final store = StudyStore(
        catalog,
        EphemeralProgress(),
        homeWidgets: bridge,
      );
      try {
        await store.load();
        final topic = catalog.topics.firstWhere(
          (t) => t.title.contains('TLB reach'),
        );
        await store.visit(topic.id);
        await store.toggleDone(catalog.topics.first.id);
        await store.toggleSaved(topic.id);
        await bridge.flush();
        final info = await bridge.info();
        expect(info['supported'], true);
        final snapshot = jsonDecode(info['snapshot'] as String);
        expect(snapshot['completed'], 1);
        expect(snapshot['saved'], 1);
        expect(snapshot['nextId'], topic.id);
        expect(snapshot['nextQuery'], topic.title);
        for (final kind in ['progress', 'topic']) {
          final bytes = (await bridge.preview(kind))!;
          expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
          final data = ByteData.sublistView(bytes);
          expect(data.getUint32(16), 720);
          expect(data.getUint32(20), 360);
          File('${Directory.systemTemp.path}/jewte-widget-$kind.png')
              .writeAsBytesSync(bytes);
          final small = await bridge.preview(kind, width: 440, height: 280);
          expect(small!.length, greaterThan(500));
        }
        await expectLater(
          channel.invokeMethod<void>('syncProgress', '{"total":0}'),
          throwsA(isA<PlatformException>()),
        );
        final after = jsonDecode((await bridge.info())['snapshot'] as String);
        expect(after['nextId'], topic.id);
        await tester.pumpWidget(JewteApp(store: store));
        await tester.pumpAndSettle();
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .push(
              MaterialPageRoute(
                builder: (_) => HomeWidgetsScreen(store: store),
              ),
            );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('widget-preview-progress')),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.byKey(const Key('widget-preview-topic')),
          200,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await bridge.flush();
        if (previous['snapshot'] != null) {
          await channel.invokeMethod<void>(
            'syncProgress',
            previous['snapshot'],
          );
        }
        store.dispose();
        bridge.dispose();
      }
    },
  );
}
