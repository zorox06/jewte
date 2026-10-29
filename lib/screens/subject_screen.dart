import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../state/study_store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'topic_detail.dart';

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({super.key, required this.store, required this.subject});
  final StudyStore store;
  final Subject subject;
  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  final query = TextEditingController();
  int filter = 0;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final store = widget.store, subject = widget.subject;
      final all = store.catalog.forSubject(subject.id),
          done = store.countDone(store.catalog.forSubject(subject.id));
      var filtered = store.catalog.search(query.text, subjectId: subject.id);
      if (filter == 1) {
        filtered = filtered
            .where((t) => !store.completed.contains(t.id))
            .toList();
      }
      if (filter == 2) {
        filtered = filtered
            .where((t) => store.completed.contains(t.id))
            .toList();
      }
      final modules = <String, List<Topic>>{};
      for (final t in filtered) {
        modules.putIfAbsent(t.module, () => []).add(t);
      }
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back to library',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        Eyebrow(subject.shortName),
                        const SizedBox(width: 14),
                        Icon(
                          subjectIcon(subject.id),
                          size: 24,
                          color: context.colors.primary,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: context.text.headlineLarge?.copyWith(
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subject.description,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.muted,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$done of ${all.length} completed',
                                style: context.text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${(done / all.length * 100).round()}%',
                              style: context.text.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: done / all.length,
                            minHeight: 5,
                            backgroundColor: context.line,
                          ),
                        ),
                        const SizedBox(height: 23),
                        TextField(
                          controller: query,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Find a concept in ${subject.shortName}…',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 21,
                            ),
                            suffixIcon: query.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      query.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var i = 0; i < 3; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Pill(
                                    [
                                      'All concepts',
                                      'Remaining',
                                      'Completed',
                                    ][i],
                                    selected: filter == i,
                                    onTap: () => setState(() => filter = i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 17),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? EmptyState(
                            icon: filter == 2
                                ? Icons.task_alt_rounded
                                : Icons.search_off_rounded,
                            title: filter == 2
                                ? 'Nothing completed here yet'
                                : 'No matching concepts',
                            description: filter == 2
                                ? 'Check off a concept when you understand it.'
                                : 'Try a shorter term or another filter.',
                          )
                        : query.text.trim().isNotEmpty
                        ? ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                            itemCount: filtered.length,
                            separatorBuilder: (_, i) =>
                                Divider(height: 1, color: context.line),
                            itemBuilder: (c, i) => TopicRow(
                              topic: filtered[i],
                              store: store,
                              onOpen: () =>
                                  openTopic(context, store, filtered[i]),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(21, 0, 21, 30),
                            itemCount: modules.length + 1,
                            itemBuilder: (context, i) {
                              if (i == modules.length) {
                                final related = store.catalog.topics
                                    .where(
                                      (t) => t.relatedSubjects.contains(
                                        subject.id,
                                      ),
                                    )
                                    .toList();
                                if (related.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 22),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Eyebrow('Shared foundations'),
                                      const SizedBox(height: 9),
                                      Text(
                                        'These concepts live in their home subject so you only check them off once.',
                                        style: context.text.bodyMedium
                                            ?.copyWith(color: context.muted),
                                      ),
                                      const SizedBox(height: 12),
                                      ...related.map(
                                        (t) => TopicRow(
                                          topic: t,
                                          store: store,
                                          showSubject: true,
                                          onOpen: () =>
                                              openTopic(context, store, t),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final entry = modules.entries.elementAt(i);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 11),
                                child: Material(
                                  color: context.colors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: context.line),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent,
                                      ),
                                      child: ExpansionTile(
                                        key: PageStorageKey(
                                          '${subject.id}-${entry.key}-$filter',
                                        ),
                                        initiallyExpanded: i == 0,
                                        maintainState: false,
                                        tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 7,
                                        ),
                                        childrenPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                        leading: Container(
                                          width: 30,
                                          height: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: context.soft,
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                          ),
                                          child: Text(
                                            '${i + 1}'.padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: context.muted,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          entry.key,
                                          style: context.text.titleMedium
                                              ?.copyWith(fontSize: 13),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            '${store.countDone(entry.value)} / ${entry.value.length} concepts',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: context.muted,
                                            ),
                                          ),
                                        ),
                                        children: [
                                          ...entry.value.map(
                                            (t) => TopicRow(
                                              topic: t,
                                              store: store,
                                              onOpen: () =>
                                                  openTopic(context, store, t),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
