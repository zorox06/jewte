import 'package:flutter/material.dart';

import '../state/study_store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'topic_detail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.store});
  final StudyStore store;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final query = TextEditingController();
  String? subject;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final results = widget.store.catalog.search(
        query.text,
        subjectId: subject,
      );
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 7, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        const Eyebrow('Find a concept'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(23, 22, 23, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What are you learning?',
                          style: context.text.headlineMedium,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          key: const Key('global-search-input'),
                          controller: query,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Try “TLB reach” or “binary search”',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: query.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      query.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Pill(
                                  'All subjects',
                                  selected: subject == null,
                                  onTap: () => setState(() => subject = null),
                                ),
                              ),
                              ...widget.store.catalog.subjects.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Pill(
                                    s.shortName,
                                    selected: subject == s.id,
                                    onTap: () => setState(() => subject = s.id),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Eyebrow(
                          query.text.isEmpty
                              ? 'Search across ${widget.store.catalog.topics.length} unique concepts'
                              : '${results.length} ${results.length == 1 ? 'concept' : 'concepts'} found',
                        ),
                        const SizedBox(height: 9),
                      ],
                    ),
                  ),
                  Expanded(
                    child: query.text.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 23,
                              vertical: 15,
                            ),
                            children: [
                              Text(
                                'A few places to begin',
                                style: context.text.titleMedium,
                              ),
                              const SizedBox(height: 15),
                              Wrap(
                                spacing: 8,
                                runSpacing: 10,
                                children: [
                                  for (final label in [
                                    'Semaphores',
                                    'Cache',
                                    'SQL',
                                    'Recursion',
                                    'Pumping lemma',
                                    'TCP',
                                  ])
                                    Pill(
                                      label,
                                      onTap: () {
                                        query.text = label;
                                        setState(() {});
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Search understands subject names, abbreviations and alternative topic wording.',
                                style: context.text.bodyMedium?.copyWith(
                                  color: context.muted,
                                ),
                              ),
                            ],
                          )
                        : results.isEmpty
                        ? const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No concepts found',
                            description: 'Try a shorter phrase or clear the subject filter.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(17, 0, 17, 30),
                            itemCount: results.length,
                            separatorBuilder: (_, i) =>
                                Divider(height: 1, color: context.line),
                            itemBuilder: (c, i) => TopicRow(
                              topic: results[i],
                              store: widget.store,
                              showSubject: true,
                              onOpen: () =>
                                  openTopic(context, widget.store, results[i]),
                            ),
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
