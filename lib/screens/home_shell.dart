import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/catalog.dart';
import '../state/study_store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'subject_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'topic_detail.dart';
import 'home_widgets_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final StudyStore store;
  @override
  HomeShellState createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int tab = 0;
  String? nicheSubject;
  bool notesOnly = false;
  final scrolls = List.generate(4, (_) => ScrollController());
  final visited = <int>{0};
  late final AnimationController fade;
  @override
  void initState() {
    super.initState();
    fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1,
    );
    widget.store.addListener(refresh);
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void navigate(int value) {
    if (value == tab) return;
    setState(() {
      tab = value;
      visited.add(value);
    });
    if (widget.store.reduceMotion || MediaQuery.disableAnimationsOf(context)) {
      fade.value = 1;
    } else {
      fade.forward(from: .55);
    }
  }

  void subject(Subject s) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SubjectScreen(store: widget.store, subject: s),
    ),
  );
  @override
  void dispose() {
    widget.store.removeListener(refresh);
    fade.dispose();
    for (final scroll in scrolls) {
      scroll.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final wide = MediaQuery.sizeOf(context).width > 850;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: store.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: store.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              if (wide)
                Container(
                  width: 215,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: context.line)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 27, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Brand(large: true),
                      const SizedBox(height: 53),
                      for (var i = 0; i < 4; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NavItem(
                            index: i,
                            selected: tab == i,
                            onTap: () => navigate(i),
                            wide: true,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        'A quieter way to prepare.',
                        style: context.text.bodyMedium?.copyWith(
                          color: context.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Eyebrow('GATE · COMPUTER SCIENCE'),
                    ],
                  ),
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 32 : 24,
                            18,
                            wide ? 32 : 17,
                            14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: !wide
                                        ? const Brand()
                                        : Eyebrow(
                                            [
                                              'Your study space',
                                              'The library',
                                              'The niche collection',
                                              'Your collection',
                                            ][tab],
                                          ),
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const Key('open-search'),
                                tooltip: 'Search all concepts',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SearchScreen(store: store),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.search_rounded,
                                  size: 24,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Settings and backup',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SettingsScreen(store: store),
                                  ),
                                ),
                                icon: const Icon(Icons.tune_rounded, size: 23),
                              ),
                            ],
                          ),
                        ),
                        if (store.saveError != null)
                          Container(
                            color: context.colors.errorContainer,
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    store.saveError!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.onErrorContainer,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      store.setReduceMotion(store.reduceMotion),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: FadeTransition(
                            opacity: fade,
                            child: IndexedStack(
                              index: tab,
                              children: List.generate(
                                4,
                                (index) => visited.contains(index)
                                    ? TickerMode(
                                        enabled: tab == index,
                                        child: page(context, index, wide),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: context.line),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: _NavItem(
                            index: i,
                            selected: tab == i,
                            onTap: () => navigate(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget page(BuildContext context, int index, bool wide) {
    final padding = EdgeInsets.fromLTRB(wide ? 35 : 24, 8, wide ? 35 : 24, 32);
    if (index == 2) return niche(context, padding);
    if (index == 3) return saved(context, padding);
    return SingleChildScrollView(
      key: PageStorageKey('home-tab-$index'),
      controller: scrolls[index],
      padding: padding,
      child: index == 0 ? overview(context) : library(context),
    );
  }

  Widget overview(BuildContext context) {
    final store = widget.store, catalog = widget.store.catalog;
    final next = store.nextTopic;
    final done = store.completed.length;
    final progress = done / catalog.topics.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Eyebrow('GATE CS / MADE FOR UNDERSTANDING'),
        const SizedBox(height: 16),
        Text(
          'Make room for\nunderstanding.',
          style: TextStyle(
            fontFamily: 'DMSerif',
            fontSize: MediaQuery.sizeOf(context).width < 360 ? 35 : 42,
            height: 1.09,
            letterSpacing: -1.6,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'One clear topic. One good explanation.\nLearn at your own pace.',
          style: context.text.bodyMedium?.copyWith(color: context.muted),
        ),
        const SizedBox(height: 27),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: JewteColors.forest,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -12,
                top: 2,
                child: Opacity(opacity: .7, child: OrbitArtwork()),
              ),
              Padding(
                padding: const EdgeInsets.all(23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('The big picture', color: Color(0xFFC4D2C3)),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress * 100),
                          duration: Duration(
                            milliseconds:
                                MediaQuery.disableAnimationsOf(context)
                                ? 0
                                : 300,
                          ),
                          builder: (c, v, w) => Text(
                            '${v.round()}',
                            style: const TextStyle(
                              fontSize: 52,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -2,
                              color: JewteColors.lime,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 5, left: 2),
                          child: Text(
                            '%',
                            style: TextStyle(
                              fontSize: 25,
                              color: JewteColors.lime,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '$done concepts understood\n${catalog.topics.length - done} still to explore',
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.65,
                                color: Color(0xFFE1E8DB),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 23),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        color: JewteColors.lime,
                        backgroundColor: const Color(0xFF496555),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          color: Color(0xFFC4D2C3),
                          size: 13,
                        ),
                        const SizedBox(width: 7),
                        const Flexible(
                          child: Text(
                            'Your progress, saved on this device',
                            style: TextStyle(
                              color: Color(0xFFC4D2C3),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Material(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: () => openTopic(context, store, next),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(color: context.line),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow(
                          store.lastTopic == null
                              ? 'A place to begin'
                              : 'Your next concept',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          next.title,
                          style: context.text.titleMedium?.copyWith(
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          key: const Key('open-widgets'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(Icons.widgets_outlined, color: context.colors.primary),
          title: Text(
            'Jewte on your home screen',
            style: context.text.titleMedium,
          ),
          subtitle: const Text('Progress and a concept, at a glance.'),
          trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HomeWidgetsScreen(store: store)),
          ),
        ),
        SectionTitle(
          'Your subjects',
          trailing: 'View all 10',
          onTap: () => navigate(1),
        ),
        subjectGrid(catalog.subjects.take(4).toList()),
        const SizedBox(height: 23),
        nicheBanner(context),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget subjectGrid(List<Subject> subjects) => LayoutBuilder(
    builder: (context, box) {
      final cols = MediaQuery.textScalerOf(context).scale(14) > 18
          ? 1
          : box.maxWidth > 750
          ? 4
          : box.maxWidth > 490
          ? 3
          : 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: subjects
            .map(
              (s) => SizedBox(
                width: (box.maxWidth - (cols - 1) * 12) / cols,
                child: SubjectCard(
                  subject: s,
                  store: widget.store,
                  onTap: () => subject(s),
                ),
              ),
            )
            .toList(),
      );
    },
  );
  Widget nicheBanner(BuildContext context) => Material(
    color: context.isDark ? const Color(0xFF303C29) : const Color(0xFFE7EDCF),
    borderRadius: BorderRadius.circular(21),
    child: InkWell(
      onTap: () => navigate(2),
      borderRadius: BorderRadius.circular(21),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(
                    '${widget.store.catalog.topics.where((t) => t.niche != null).length} CURATED PYQ DETAILS',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Beyond the obvious.',
                    style: TextStyle(
                      fontFamily: 'DMSerif',
                      fontSize: 26,
                      letterSpacing: -.6,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'The niche concepts hiding inside familiar topics.',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              Icons.north_east_rounded,
              size: 27,
              color: context.colors.primary,
            ),
          ],
        ),
      ),
    ),
  );
  Widget library(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      const Eyebrow('10 SUBJECTS / ONE CLEAR LIBRARY'),
      const SizedBox(height: 15),
      Text('The whole picture.', style: context.text.headlineLarge),
      const SizedBox(height: 13),
      Text(
        'All your technical subjects, organised into concepts.\nNo aptitude. No mathematics. No countdowns.',
        style: context.text.bodyMedium?.copyWith(color: context.muted),
      ),
      const SizedBox(height: 24),
      InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SearchScreen(store: widget.store)),
        ),
        borderRadius: BorderRadius.circular(17),
        child: InputDecorator(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded, size: 21),
          ),
          child: Text(
            'Search ${widget.store.catalog.topics.length} unique concepts…',
            style: TextStyle(fontSize: 12, color: context.muted),
          ),
        ),
      ),
      const SizedBox(height: 23),
      subjectGrid(widget.store.catalog.subjects),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.link_rounded, size: 17, color: context.muted),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Shared foundations have one home subject and one progress record. You can find them from every relevant subject.',
              style: context.text.bodyMedium?.copyWith(
                color: context.muted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    ],
  );
  Widget niche(BuildContext context, EdgeInsets padding) {
    final store = widget.store;
    final topics = store.catalog.topics
        .where(
          (t) =>
              t.niche != null &&
              (nicheSubject == null || t.subjectId == nicheSubject),
        )
        .toList();
    return CustomScrollView(
      key: const PageStorageKey('home-tab-2'),
      controller: scrolls[2],
      slivers: [
        SliverPadding(
          padding: padding.copyWith(bottom: 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Eyebrow('CURATED FROM YOUR PYQs'),
                const SizedBox(height: 15),
                Text(
                  'The niche collection.',
                  style: context.text.headlineLarge,
                ),
                const SizedBox(height: 13),
                Text(
                  'Small details. Surprisingly different questions.\nLook a little closer at what has been asked.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.muted,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: context.soft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: context.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A curated view of the same topics, with PYQ page references. Completion stays in sync with your syllabus.',
                          style: context.text.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: context.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Pill(
                          'All subjects',
                          selected: nicheSubject == null,
                          onTap: () => setState(() => nicheSubject = null),
                        ),
                      ),
                      ...store.catalog.subjects.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Pill(
                            s.shortName,
                            selected: nicheSubject == s.id,
                            onTap: () => setState(() => nicheSubject = s.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: padding.copyWith(top: 0),
          sliver: SliverList.builder(
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final t = topics[index],
                  n = t.niche!,
                  s = store.catalog.subjectsById[t.subjectId]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: () => openTopic(context, store, t),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(21),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.line),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 29,
                                height: 29,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.soft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  subjectIcon(s.id),
                                  size: 17,
                                  color: context.colors.primary,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Eyebrow(s.shortName),
                              const Spacer(),
                              if (store.completed.contains(t.id))
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 19,
                                  color: context.colors.primary,
                                )
                              else
                                Text(
                                  '${index + 1}'.padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.muted,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 17),
                          Text(
                            n.label,
                            style: context.text.titleLarge?.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            n.why,
                            style: context.text.bodyMedium?.copyWith(
                              color: context.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'PYQ PDF · ${n.pages.length == 1 ? 'p.' : 'pp.'} ${n.pages.join(', ')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.muted,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'Explore concept',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_outward_rounded,
                                size: 16,
                                color: context.colors.primary,
                              ),
                            ],
                          ),
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
    );
  }

  Widget saved(BuildContext context, EdgeInsets padding) {
    final store = widget.store;
    final topics = store.catalog.topics
        .where(
          (t) => notesOnly
              ? store.notes.containsKey(t.id)
              : store.saved.contains(t.id),
        )
        .toList();
    return CustomScrollView(
      key: const PageStorageKey('home-tab-3'),
      controller: scrolls[3],
      slivers: [
        SliverPadding(
          padding: padding.copyWith(bottom: 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Eyebrow('A SPACE FOR WHAT MATTERS'),
                const SizedBox(height: 15),
                Text('Keep it close.', style: context.text.headlineLarge),
                const SizedBox(height: 13),
                Text(
                  'Concepts to revisit. Explanations to remember.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.muted,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Pill(
                      'Saved (${store.saved.length})',
                      icon: Icons.bookmark_border_rounded,
                      selected: !notesOnly,
                      onTap: () => setState(() => notesOnly = false),
                    ),
                    Pill(
                      'Notes (${store.notes.length})',
                      icon: Icons.edit_note_rounded,
                      selected: notesOnly,
                      onTap: () => setState(() => notesOnly = true),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (topics.isEmpty)
                  EmptyState(
                    icon: notesOnly
                        ? Icons.edit_note_rounded
                        : Icons.bookmark_border_rounded,
                    title: notesOnly
                        ? 'Your notes belong here'
                        : 'A collection, made by you',
                    description: notesOnly
                        ? 'Open any concept and add the explanation you want to keep.'
                        : 'Save a concept using its bookmark. You can return to it here.',
                    action: OutlinedButton(
                      onPressed: () => navigate(1),
                      child: const Text('Explore the library'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: padding.copyWith(top: 0),
          sliver: SliverList.builder(
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final t = topics[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TopicRow(
                      topic: t,
                      store: store,
                      showSubject: true,
                      onOpen: () => openTopic(context, store, t),
                    ),
                    if (notesOnly)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(48, 0, 17, 16),
                        child: Text(
                          store.notes[t.id]!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selected,
    required this.onTap,
    this.wide = false,
  });
  final int index;
  final bool selected, wide;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final label = ['Overview', 'Subjects', 'Niche', 'Saved'][index];
    final icon = [
      Icons.space_dashboard_outlined,
      Icons.auto_stories_outlined,
      Icons.explore_outlined,
      Icons.bookmark_border_rounded,
    ][index];
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('nav-$index'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: AnimatedContainer(
            duration: Duration(
              milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 200,
            ),
            padding: EdgeInsets.symmetric(
              vertical: wide ? 15 : 10,
              horizontal: wide ? 15 : 3,
            ),
            decoration: BoxDecoration(
              color: selected ? context.colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
            ),
            child: wide
                ? Row(
                    children: [
                      Icon(
                        icon,
                        size: 21,
                        color: selected
                            ? context.colors.onPrimary
                            : context.muted,
                      ),
                      const SizedBox(width: 11),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? context.colors.onPrimary
                              : context.muted,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 21,
                        color: selected
                            ? context.colors.onPrimary
                            : context.muted,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? context.colors.onPrimary
                              : context.muted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
