import 'dart:convert';

import 'package:flutter/services.dart';

class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.icon,
    required this.pyqPages,
  });
  final String id, name, shortName, description, icon;
  final List<int> pyqPages;
  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'],
    name: json['name'],
    shortName: json['short'],
    description: json['description'],
    icon: json['icon'],
    pyqPages: List<int>.from(json['pyqPages']),
  );
}

class NicheNote {
  const NicheNote(this.label, this.why, this.pages);
  final String label, why;
  final List<int> pages;
  factory NicheNote.fromJson(Map<String, dynamic> json) =>
      NicheNote(json['label'], json['why'], List<int>.from(json['pages']));
}

class Topic {
  Topic({
    required this.id,
    required this.subjectId,
    required this.module,
    required this.title,
    required this.kind,
    required this.query,
    required this.aliases,
    required this.relatedSubjects,
    required this.detail,
    this.niche,
  });
  final String id, subjectId, module, title, kind, query, detail;
  final List<String> aliases, relatedSubjects;
  final NicheNote? niche;
  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'],
    subjectId: json['subjectId'],
    module: json['module'],
    title: json['title'],
    kind: json['kind'],
    query: json['query'],
    aliases: List<String>.from(json['aliases']),
    relatedSubjects: List<String>.from(json['relatedSubjects']),
    detail: json['detail'],
    niche: json['niche'] == null ? null : NicheNote.fromJson(json['niche']),
  );

  // Use the topic itself: no exam, course, channel or subject prefix/suffix.
  String get youtubeQuery => title;
  Uri get youtubeUri =>
      Uri.https('www.youtube.com', '/results', {'search_query': youtubeQuery});
  late final String searchText = '$title $module $query ${aliases.join(' ')}'
      .toLowerCase();
}

class Catalog {
  Catalog(this.subjects, this.topics)
    : byId = {for (final t in topics) t.id: t},
      subjectsById = {for (final s in subjects) s.id: s};
  final List<Subject> subjects;
  final List<Topic> topics;
  final Map<String, Topic> byId;
  final Map<String, Subject> subjectsById;
  late final Map<String, List<Topic>> _subjectTopics = {
    for (final subject in subjects)
      subject.id: List.unmodifiable(
        topics.where((t) => t.subjectId == subject.id),
      ),
  };
  late final Map<String, String> _searchEntries = {
    for (final topic in topics)
      topic.id:
          '${topic.searchText} ${subjectsById[topic.subjectId]!.name.toLowerCase()} ${subjectsById[topic.subjectId]!.shortName.toLowerCase()}',
  };
  static Future<Catalog> load() async => Catalog.fromJson(
    jsonDecode(await rootBundle.loadString('assets/data/catalog.json')),
  );
  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
    (json['subjects'] as List).map((v) => Subject.fromJson(v)).toList(),
    (json['topics'] as List).map((v) => Topic.fromJson(v)).toList(),
  );
  List<Topic> forSubject(String id) => _subjectTopics[id] ?? const [];
  List<Topic> search(
    String query, {
    String? subjectId,
    bool nicheOnly = false,
  }) {
    final words = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty);
    final candidates = subjectId == null ? topics : forSubject(subjectId);
    final found = candidates.where((topic) {
      if (subjectId != null && topic.subjectId != subjectId) return false;
      if (nicheOnly && topic.niche == null) return false;
      final haystack = _searchEntries[topic.id]!;
      return words.every(haystack.contains);
    }).toList();
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      found.sort((a, b) {
        int rank(Topic t) => t.title.toLowerCase() == q
            ? 0
            : t.title.toLowerCase().startsWith(q)
            ? 1
            : 2;
        return rank(a).compareTo(rank(b));
      });
    }
    return found;
  }
}
