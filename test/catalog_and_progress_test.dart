import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jewte/models/catalog.dart';
import 'package:jewte/state/study_store.dart';

class MemoryRepository implements ProgressRepository {
  String? value;
  bool fail = false;
  final writes = <String>[];
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String data) async {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    if (fail) throw const FileSystemException('Simulated unavailable disk');
    writes.add(data);
    value = data;
  }
}

Catalog testCatalog() => Catalog.fromJson(
  jsonDecode(File('assets/data/catalog.json').readAsStringSync()),
);

void main() {
  late Catalog catalog;
  setUp(() => catalog = testCatalog());
  test(
    'catalog has one owner and ID per concept, and 41 existing niche records',
    () {
      expect(catalog.subjects.length, 10);
      expect(catalog.topics.length, greaterThan(1500));
      expect(
        catalog.topics.map((t) => t.id).toSet().length,
        catalog.topics.length,
      );
      String normalized(String s) =>
          s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
      expect(
        catalog.topics.map((t) => normalized(t.title)).toSet().length,
        catalog.topics.length,
      );
      expect(catalog.topics.where((t) => t.niche != null).length, 41);
      for (final topic in catalog.topics) {
        expect(catalog.subjectsById.containsKey(topic.subjectId), isTrue);
        expect(topic.query.trim(), isNotEmpty);
        expect(topic.title.contains('PYQs:'), isFalse);
        if (topic.niche != null) {
          expect(topic.niche!.pages.every((p) => p >= 7 && p <= 582), isTrue);
          expect(identical(catalog.byId[topic.id], topic), isTrue);
        }
      }
      expect(
        catalog.search('Heap sort').where((t) => t.title == 'Heap sort').length,
        1,
      );
      expect(
        catalog
            .search('Endianness')
            .where((t) => t.title == 'Endianness')
            .length,
        1,
      );
    },
  );
  test('search supports case, all words, aliases and subject filters', () {
    expect(
      catalog.search('TLB REACH').any((t) => t.title.contains('TLB reach')),
      isTrue,
    );
    expect(
      catalog
          .search('Booth arithmetic')
          .any((t) => t.title == "Booth's multiplication algorithm"),
      isTrue,
    );
    expect(
      catalog
          .search('semaphore', subjectId: 'os')
          .every((t) => t.subjectId == 'os'),
      isTrue,
    );
    expect(catalog.search('zzunfindablezz'), isEmpty);
    expect(catalog.search('', nicheOnly: true).length, 41);
  });
  test('YouTube URI preserves query safely as a search, not a video URL', () {
    final t = catalog.topics.firstWhere((t) => t.title.contains('First Come'));
    expect(t.youtubeUri.scheme, 'https');
    expect(t.youtubeUri.host, 'www.youtube.com');
    expect(t.youtubeUri.path, '/results');
    expect(t.youtubeUri.queryParameters['search_query'], t.title);
    for (final topic in catalog.topics) {
      expect(topic.youtubeUri.queryParameters, {'search_query': topic.title});
      expect(topic.query, topic.title);
    }
  });
  test(
    'completion, bookmarks, notes, recents and preferences survive reopening',
    () async {
      final repo = MemoryRepository(),
          store = StudyStore(catalog, MemoryRepository());
      final first = catalog.topics.first.id;
      final actual = StudyStore(catalog, repo);
      await actual.toggleDone(first);
      await actual.toggleSaved(first);
      await actual.setNote(
        first,
        '  A useful video link and an explanation.  ',
      );
      await actual.visit(first);
      await actual.setDark(true);
      await actual.setReduceMotion(true);
      final reopened = StudyStore(catalog, repo);
      await reopened.load();
      expect(reopened.completed, {first});
      expect(reopened.saved, {first});
      expect(reopened.notes[first], 'A useful video link and an explanation.');
      expect(reopened.lastTopic!.id, first);
      expect(reopened.dark, isTrue);
      expect(reopened.reduceMotion, isTrue);
      await reopened.toggleDone(first);
      await reopened.toggleSaved(first);
      await reopened.setNote(first, '');
      final again = StudyStore(catalog, repo);
      await again.load();
      expect(again.completed, isEmpty);
      expect(again.saved, isEmpty);
      expect(again.notes, isEmpty);
      store.dispose();
      actual.dispose();
      reopened.dispose();
      again.dispose();
    },
  );
  test(
    'rapid actions are serialized without losing a more recent state',
    () async {
      final repo = MemoryRepository();
      final store = StudyStore(catalog, repo);
      final id = catalog.topics.first.id;
      final a = store.toggleDone(id),
          b = store.toggleSaved(id),
          c = store.toggleDone(id);
      await Future.wait([a, b, c]);
      final reopened = StudyStore(catalog, repo);
      await reopened.load();
      expect(reopened.completed, isEmpty);
      expect(reopened.saved, {id});
      expect(repo.writes.length, 3);
    },
  );
  test(
    'invalid backup is rejected before modifying existing progress',
    () async {
      final store = StudyStore(catalog, MemoryRepository());
      final id = catalog.topics.first.id;
      await store.toggleDone(id);
      await store.setNote(id, 'Keep me');
      final before = store.exportBackup();
      await expectLater(
        store.importBackup('{"app":"jewte","version":1}'),
        throwsFormatException,
      );
      expect(store.exportBackup(), before);
      await expectLater(store.importBackup('not JSON'), throwsFormatException);
      expect(store.exportBackup(), before);
    },
  );
  test(
    'backup round trip filters obsolete IDs and preserves known data',
    () async {
      final source = StudyStore(catalog, MemoryRepository());
      final id = catalog.topics.first.id;
      await source.toggleDone(id);
      await source.toggleSaved(id);
      await source.setNote(id, 'Preserve this');
      final json = jsonDecode(source.exportBackup());
      json['completed'].add('obsolete-id');
      json['notes']['obsolete-id'] = 'Old note';
      final restored = StudyStore(catalog, MemoryRepository());
      await restored.importBackup(jsonEncode(json));
      expect(restored.completed, {id});
      expect(restored.saved, {id});
      expect(restored.notes, {id: 'Preserve this'});
    },
  );
  test(
    'failed storage write is visible and a retry clears the error',
    () async {
      final repo = MemoryRepository()..fail = true;
      final store = StudyStore(catalog, repo);
      await store.toggleDone(catalog.topics.first.id);
      expect(store.saveError, isNotNull);
      expect(repo.value, isNull);
      repo.fail = false;
      await store.setReduceMotion(false);
      expect(store.saveError, isNull);
      final reopened = StudyStore(catalog, repo);
      await reopened.load();
      expect(reopened.completed, {catalog.topics.first.id});
    },
  );
}
