import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../platform/home_widgets.dart';
import '../state/study_store.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeWidgetsScreen extends StatefulWidget {
  const HomeWidgetsScreen({super.key, required this.store});
  final StudyStore store;
  @override
  State<HomeWidgetsScreen> createState() => _HomeWidgetsScreenState();
}

class _HomeWidgetsScreenState extends State<HomeWidgetsScreen> {
  final previews = <String, Uint8List>{};
  bool pinning = false;
  HomeWidgetBridge? get bridge => widget.store.homeWidgets;
  @override
  void initState() {
    super.initState();
    loadPreviews();
  }

  Future<void> loadPreviews() async {
    try {
      await bridge?.flush();
      for (final kind in ['progress', 'topic']) {
        final bytes = await bridge?.preview(kind);
        if (bytes != null && mounted) setState(() => previews[kind] = bytes);
      }
    } catch (_) {
      /* The gallery remains usable with the text preview. */
    }
  }

  Future<void> pin(String kind) async {
    setState(() => pinning = true);
    var requested = false;
    try {
      requested = await bridge?.requestPin(kind) ?? false;
    } catch (_) {}
    if (!mounted) return;
    setState(() => pinning = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          requested
              ? 'Confirm placement with your launcher.'
              : 'Long-press your home screen, choose Widgets, then find Jewte.',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 7, 24, 36),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: 24),
              const Eyebrow('A LITTLE CLOSER'),
              const SizedBox(height: 12),
              Text(
                'At a glance.\nReady to continue.',
                style: context.text.headlineLarge,
              ),
              const SizedBox(height: 14),
              Text(
                'Two home-screen widgets that keep your study space within reach.',
                style: context.text.bodyMedium?.copyWith(color: context.muted),
              ),
              const SizedBox(height: 28),
              card(
                context,
                'progress',
                'Your progress',
                'See completed concepts and what’s left. Tap to open your subjects.',
              ),
              const SizedBox(height: 22),
              card(
                context,
                'topic',
                'Next concept',
                'Continue where you left off or search the exact topic on YouTube.',
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.soft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'You can also long-press your home screen → Widgets → Jewte. Resize either widget to suit your layout. Progress refreshes after changes are saved in the app.',
                  style: context.text.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: context.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget card(
    BuildContext context,
    String kind,
    String title,
    String description,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border.all(color: context.line),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (previews[kind] case final Uint8List bytes)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(
              bytes,
              key: Key('widget-preview-$kind'),
              width: double.infinity,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          )
        else
          preview(context, kind),
        const SizedBox(height: 20),
        Text(title, style: context.text.titleLarge),
        const SizedBox(height: 7),
        Text(
          description,
          style: context.text.bodyMedium?.copyWith(
            color: context.muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: Key('pin-widget-$kind'),
          onPressed: pinning ? null : () => pin(kind),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add to home screen'),
        ),
      ],
    ),
  );
  Widget preview(BuildContext context, String kind) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: JewteColors.forest,
      borderRadius: BorderRadius.circular(18),
    ),
    child: DefaultTextStyle(
      style: const TextStyle(fontFamily: 'Manrope', color: JewteColors.paper),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind == 'progress'
                ? 'jewte / YOUR PROGRESS'
                : 'jewte / NEXT CONCEPT',
            style: const TextStyle(
              fontSize: 10,
              color: JewteColors.lime,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            kind == 'progress'
                ? '${(widget.store.completed.length / widget.store.catalog.topics.length * 100).round()}%'
                : widget.store.nextTopic.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: kind == 'progress' ? 36 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            kind == 'progress'
                ? '${widget.store.completed.length} of ${widget.store.catalog.topics.length} concepts'
                : 'Open concept     ·     YouTube ↗',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
