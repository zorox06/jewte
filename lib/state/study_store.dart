import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalog.dart';
import '../platform/home_widgets.dart';

abstract class ProgressRepository {
  Future<String?> read();
  Future<void> write(String data);
}

class DeviceProgressRepository implements ProgressRepository {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const key = 'jewte.progress.v1';
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String data) => _preferences.setString(key, data);
}

class StudyStore extends ChangeNotifier {
  StudyStore(this.catalog, this.repository, {this.homeWidgets});
  final Catalog catalog;
  final ProgressRepository repository;
  final HomeWidgetBridge? homeWidgets;
  final Set<String> completed = {}, saved = {};
  final Map<String, String> notes = {};
  final List<String> recent = [];
  bool dark = false, reduceMotion = false;
  String? saveError;
  Future<void> _pending = Future.value();
  Future<void> get settled => _pending;

  Future<void> load() async {
    final data = await repository.read();
    if (data != null) _restore(jsonDecode(data));
    homeWidgets?.scheduleSync(widgetSnapshot());
  }

  int countDone(Iterable<Topic> topics) =>
      topics.where((t) => completed.contains(t.id)).length;
  double progress(Iterable<Topic> topics) {
    final list = topics.toList();
    return list.isEmpty ? 0 : countDone(list) / list.length;
  }

  Topic? get lastTopic => recent.isEmpty ? null : catalog.byId[recent.first];
  Topic get nextTopic {
    if (lastTopic != null) {
      if (!completed.contains(lastTopic!.id)) return lastTopic!;
      final same = catalog.forSubject(lastTopic!.subjectId);
      final index = same.indexWhere((t) => t.id == lastTopic!.id);
      final following = [...same.skip(index + 1), ...same.take(index + 1)];
      final incomplete = following.where((t) => !completed.contains(t.id));
      if (incomplete.isNotEmpty) return incomplete.first;
    }
    return catalog.topics.firstWhere(
      (t) => !completed.contains(t.id),
      orElse: () => catalog.topics.first,
    );
  }

  Future<void> toggleDone(String id) {
    if (!catalog.byId.containsKey(id)) throw ArgumentError('Unknown topic');
    completed.contains(id) ? completed.remove(id) : completed.add(id);
    return _save();
  }

  Future<void> toggleSaved(String id) {
    if (!catalog.byId.containsKey(id)) throw ArgumentError('Unknown topic');
    saved.contains(id) ? saved.remove(id) : saved.add(id);
    return _save();
  }

  Future<void> setNote(String id, String text) {
    if (!catalog.byId.containsKey(id)) throw ArgumentError('Unknown topic');
    final trimmed = text.trim();
    if (trimmed.length > 10000) {
      throw ArgumentError('Note exceeds 10,000 characters');
    }
    trimmed.isEmpty ? notes.remove(id) : notes[id] = trimmed;
    return _save();
  }

  Future<void> visit(String id) {
    if (!catalog.byId.containsKey(id)) return Future.value();
    recent.remove(id);
    recent.insert(0, id);
    if (recent.length > 20) recent.removeRange(20, recent.length);
    return _save();
  }

  Future<void> setDark(bool value) {
    dark = value;
    return _save();
  }

  Future<void> setReduceMotion(bool value) {
    reduceMotion = value;
    return _save();
  }

  String exportBackup() =>
      const JsonEncoder.withIndent('  ').convert(_snapshot());
  Map<String, Object?> widgetSnapshot() {
    final next = nextTopic;
    return {
      'total': catalog.topics.length,
      'completed': completed.length,
      'saved': saved.length,
      'nextId': next.id,
      'nextTitle': next.title,
      'nextSubject': catalog.subjectsById[next.subjectId]!.name,
      'nextQuery': next.youtubeQuery,
    };
  }

  Future<void> importBackup(String source) async {
    if (source.length > 2000000) {
      throw const FormatException('Backup is too large.');
    }
    final data = jsonDecode(source);
    // Validate the entire payload before mutating existing progress.
    _validate(data);
    _restore(data);
    await _save();
  }

  void _validate(dynamic data) {
    if (data is! Map<String, dynamic> ||
        data['app'] != 'jewte' ||
        data['version'] != 1) {
      throw const FormatException('This is not a supported Jewte backup.');
    }
    for (final key in ['completed', 'saved', 'recent']) {
      if (data[key] is! List ||
          !(data[key] as List).every((v) => v is String)) {
        throw FormatException('Invalid $key data.');
      }
    }
    if (data['notes'] is! Map ||
        !(data['notes'] as Map).entries.every(
          (v) =>
              v.key is String &&
              v.value is String &&
              (v.value as String).length <= 10000,
        )) {
      throw const FormatException('Invalid notes data.');
    }
    if (data['dark'] is! bool || data['reduceMotion'] is! bool) {
      throw const FormatException('Invalid preferences.');
    }
  }

  void _restore(dynamic data) {
    _validate(data);
    final ids = catalog.byId.keys.toSet();
    completed
      ..clear()
      ..addAll((data['completed'] as List).cast<String>().where(ids.contains));
    saved
      ..clear()
      ..addAll((data['saved'] as List).cast<String>().where(ids.contains));
    recent
      ..clear()
      ..addAll(
        (data['recent'] as List)
            .cast<String>()
            .where(ids.contains)
            .toSet()
            .take(20),
      );
    notes
      ..clear()
      ..addAll(
        Map<String, String>.from(data['notes'])
          ..removeWhere((k, v) => !ids.contains(k)),
      );
    dark = data['dark'];
    reduceMotion = data['reduceMotion'];
  }

  Map<String, dynamic> _snapshot() => {
    'app': 'jewte',
    'version': 1,
    'completed': completed.toList()..sort(),
    'saved': saved.toList()..sort(),
    'notes': Map.of(notes),
    'recent': List.of(recent),
    'dark': dark,
    'reduceMotion': reduceMotion,
  };
  Future<void> _save() {
    final payload = jsonEncode(_snapshot());
    final widgetData = widgetSnapshot();
    notifyListeners();
    _pending = _pending.then((_) async {
      try {
        await repository.write(payload);
        final hadError = saveError != null;
        saveError = null;
        homeWidgets?.scheduleSync(widgetData);
        if (hadError) notifyListeners();
      } catch (_) {
        saveError =
            'Progress could not be saved. Keep the app open and try again.';
        notifyListeners();
      }
    });
    return _pending;
  }
}
