import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/catalog.dart';
import '../state/study_store.dart';
import '../theme.dart';
import '../widgets.dart';

Future<void> openTopic(
  BuildContext context,
  StudyStore store,
  Topic topic,
) async {
  store.visit(topic.id);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) => TopicDetail(store: store, topic: topic),
  );
}

class TopicDetail extends StatefulWidget {
  const TopicDetail({super.key, required this.store, required this.topic});
  final StudyStore store;
  final Topic topic;
  @override
  State<TopicDetail> createState() => _TopicDetailState();
}

class _TopicDetailState extends State<TopicDetail> {
  late final TextEditingController note = TextEditingController(
    text: widget.store.notes[widget.topic.id] ?? '',
  );
  bool editing = false, saving = false;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> watch() async {
    try {
      final launched = await launchUrl(
        widget.topic.youtubeUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        showMessage('Could not open YouTube. Use Copy search instead.');
      }
    } catch (_) {
      if (mounted) {
        showMessage('Could not open YouTube. Use Copy search instead.');
      }
    }
  }

  void showMessage(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final topic = widget.topic, store = widget.store;
      final subject = store.catalog.subjectsById[topic.subjectId]!;
      final done = store.completed.contains(topic.id),
          saved = store.saved.contains(topic.id);
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Eyebrow(subject.name)),
                  IconButton(
                    tooltip: saved ? 'Remove from saved' : 'Save topic',
                    onPressed: () => store.toggleSaved(topic.id),
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close topic',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(topic.title, style: context.text.headlineMedium),
              const SizedBox(height: 12),
              Text(
                topic.module,
                style: context.text.bodyMedium?.copyWith(color: context.muted),
              ),
              if (topic.kind != 'core') ...[
                const SizedBox(height: 12),
                Pill(switch (topic.kind) {
                  'supporting' => 'Supporting concept',
                  'legacy' => 'Legacy PYQ coverage',
                  _ => 'PYQ extension',
                }),
              ],
              if (topic.niche != null) ...[
                const SizedBox(height: 23),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: context.soft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.explore_outlined,
                            size: 17,
                            color: context.colors.primary,
                          ),
                          const SizedBox(width: 7),
                          const Eyebrow('The detail that matters'),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Text(topic.niche!.why, style: context.text.bodyMedium),
                      const SizedBox(height: 12),
                      Text(
                        'Supplied PYQ PDF · ${topic.niche!.pages.length == 1 ? 'page' : 'pages'} ${topic.niche!.pages.join(', ')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (topic.detail.isNotEmpty) ...[
                const SizedBox(height: 23),
                const Eyebrow('Also covers'),
                const SizedBox(height: 8),
                ...topic.aliases.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: TextStyle(color: context.muted)),
                        Expanded(
                          child: Text(
                            a,
                            style: context.text.bodyMedium?.copyWith(
                              color: context.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (topic.relatedSubjects.isNotEmpty) ...[
                const SizedBox(height: 15),
                Text(
                  'Also useful in ${topic.relatedSubjects.map((s) => store.catalog.subjectsById[s]!.name).join(', ')}. This is one shared topic, with one progress record.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.muted,
                  ),
                ),
              ],
              const SizedBox(height: 25),
              const Eyebrow('Find your explanation'),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.fromLTRB(15, 12, 6, 12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.line),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.youtubeQuery,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.muted,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy YouTube search',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: topic.youtubeQuery),
                        );
                        if (mounted) showMessage('Search phrase copied.');
                      },
                      icon: const Icon(Icons.copy_outlined, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: watch,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 21),
                  label: const Text('Search on YouTube'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => store.toggleDone(topic.id),
                  icon: Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                  ),
                  label: Text(
                    done
                        ? 'Completed · mark as remaining'
                        : 'Mark as completed',
                  ),
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Expanded(
                    child: Text('Your notes', style: context.text.titleMedium),
                  ),
                  TextButton(
                    onPressed: () => setState(() => editing = !editing),
                    child: Text(
                      editing
                          ? 'Cancel'
                          : store.notes.containsKey(topic.id)
                          ? 'Edit'
                          : 'Add note',
                    ),
                  ),
                ],
              ),
              if (editing) ...[
                TextField(
                  controller: note,
                  minLines: 3,
                  maxLines: 7,
                  maxLength: 10000,
                  decoration: const InputDecoration(
                    hintText: 'A useful explanation, a video link, or what finally clicked…',
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setState(() => saving = true);
                            await store.setNote(topic.id, note.text);
                            if (mounted) {
                              setState(() {
                                saving = false;
                                editing = false;
                              });
                            }
                          },
                    child: const Text('Save note'),
                  ),
                ),
              ] else
                Text(
                  store.notes[topic.id] ??
                      'Keep the explanation that made it click.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.muted,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
