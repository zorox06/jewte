import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/catalog.dart';
import 'state/study_store.dart';
import 'theme.dart';

IconData subjectIcon(String id) => switch (id) {
  'c' => Icons.code_rounded,
  'ds' => Icons.account_tree_outlined,
  'algorithms' => Icons.route_outlined,
  'digital' => Icons.memory_rounded,
  'coa' => Icons.developer_board_outlined,
  'toc' => Icons.all_inclusive_rounded,
  'compiler' => Icons.terminal_rounded,
  'os' => Icons.layers_outlined,
  'db' => Icons.storage_rounded,
  'cn' => Icons.hub_outlined,
  _ => Icons.school_outlined,
};

class Brand extends StatelessWidget {
  const Brand({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: large ? 43 : 36,
        height: large ? 43 : 36,
        decoration: BoxDecoration(
          color: JewteColors.forest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const CustomPaint(painter: _JewteMark()),
      ),
      const SizedBox(width: 10),
      Text(
        'jewte',
        style: TextStyle(
          fontSize: large ? 30 : 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.6,
          color: context.colors.onSurface,
        ),
      ),
    ],
  );
}

// One geometric book/check mark, shared with the Android vector launcher icon.
class _JewteMark extends CustomPainter {
  const _JewteMark();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 108, size.height / 108);
    final left = Path()
      ..moveTo(24, 29)
      ..lineTo(47, 35)
      ..quadraticBezierTo(52, 37, 52, 42)
      ..lineTo(52, 80)
      ..lineTo(46, 75)
      ..lineTo(24, 69)
      ..close();
    final right = Path()
      ..moveTo(56, 42)
      ..quadraticBezierTo(56, 37, 61, 35)
      ..lineTo(84, 29)
      ..lineTo(84, 69)
      ..lineTo(62, 75)
      ..lineTo(56, 80)
      ..close();
    canvas.drawPath(left, Paint()..color = JewteColors.paper);
    canvas.drawPath(right, Paint()..color = JewteColors.lime);
    final check = Path()
      ..moveTo(63, 54)
      ..lineTo(69, 60)
      ..lineTo(78, 46);
    canvas.drawPath(
      check,
      Paint()
        ..color = JewteColors.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JewteMark oldDelegate) => false;
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.label, {super.key, this.color});
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: context.text.labelSmall?.copyWith(color: color ?? context.muted),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing, this.onTap});
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 29, bottom: 15),
    child: Builder(
      builder: (context) {
        final action = trailing == null
            ? null
            : TextButton(
                onPressed: onTap,
                child: Text(
                  trailing!,
                  style: TextStyle(color: context.muted, fontSize: 12),
                ),
              );
        if (MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleLarge),
              ?action,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: Text(title, style: context.text.titleLarge)),
            ?action,
          ],
        );
      },
    ),
  );
}

class Enter extends StatelessWidget {
  const Enter({super.key, required this.child, this.reduced = false});
  final Widget child;
  final bool reduced;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: reduced ? 1 : 0, end: 1),
    duration: Duration(milliseconds: reduced ? 0 : 420),
    curve: Curves.easeOutCubic,
    builder: (c, v, w) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: w),
    ),
    child: child,
  );
}

class ProgressRing extends StatelessWidget {
  const ProgressRing(
    this.value, {
    super.key,
    this.size = 48,
    this.color,
    this.child,
    this.reduced = false,
  });
  final double value, size;
  final Color? color;
  final Widget? child;
  final bool reduced;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: Duration(
            milliseconds: reduced || MediaQuery.disableAnimationsOf(context)
                ? 0
                : 300,
          ),
          curve: Curves.easeOutCubic,
          builder: (c, v, w) => CustomPaint(
            size: Size.square(size),
            painter: _Ring(v, color ?? context.colors.primary, context.soft),
          ),
        ),
        child ??
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: size * .2,
                fontWeight: FontWeight.w800,
              ),
            ),
      ],
    ),
  );
}

class _Ring extends CustomPainter {
  _Ring(this.progress, this.foreground, this.background);
  final double progress;
  final Color foreground, background;
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = background;
    canvas.drawArc(r, 0, math.pi * 2, false, paint);
    paint.color = foreground;
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.progress != progress ||
      old.foreground != foreground ||
      old.background != background;
}

class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.store,
    required this.onTap,
  });
  final Subject subject;
  final StudyStore store;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final topics = store.catalog.forSubject(subject.id);
    final done = store.countDone(topics);
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: context.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      subjectIcon(subject.id),
                      size: 22,
                      color: context.colors.primary,
                    ),
                  ),
                  Text(
                    subject.shortName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: context.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                subject.name,
                style: context.text.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '$done / ${topics.length} concepts',
                style: TextStyle(fontSize: 11, color: context.muted),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: topics.isEmpty ? 0 : done / topics.length,
                  ),
                  duration: Duration(
                    milliseconds: MediaQuery.disableAnimationsOf(context)
                        ? 0
                        : 240,
                  ),
                  builder: (c, v, w) => LinearProgressIndicator(
                    value: v,
                    minHeight: 3,
                    color: context.colors.primary,
                    backgroundColor: context.soft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopicRow extends StatelessWidget {
  const TopicRow({
    super.key,
    required this.topic,
    required this.store,
    required this.onOpen,
    this.showSubject = false,
  });
  final Topic topic;
  final StudyStore store;
  final VoidCallback onOpen;
  final bool showSubject;
  @override
  Widget build(BuildContext context) {
    final done = store.completed.contains(topic.id);
    final saved = store.saved.contains(topic.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: done ? 'Mark as remaining' : 'Mark as completed',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    store.toggleDone(topic.id);
                  },
                  icon: AnimatedContainer(
                    duration: Duration(
                      milliseconds: MediaQuery.disableAnimationsOf(context)
                          ? 0
                          : 160,
                    ),
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: done ? context.colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: done
                            ? context.colors.primary
                            : context.muted.withValues(alpha: .5),
                        width: 1.4,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: Duration(
                        milliseconds: MediaQuery.disableAnimationsOf(context)
                            ? 0
                            : 160,
                      ),
                      child: done
                          ? Icon(
                              Icons.check_rounded,
                              key: const ValueKey('checked'),
                              size: 17,
                              color: context.colors.onPrimary,
                            )
                          : const SizedBox(key: ValueKey('empty')),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: context.text.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: done
                              ? context.muted
                              : context.colors.onSurface,
                        ),
                      ),
                      if (showSubject ||
                          topic.niche != null ||
                          saved ||
                          topic.kind != 'core') ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 7,
                          runSpacing: 3,
                          children: [
                            if (showSubject)
                              Text(
                                store
                                    .catalog
                                    .subjectsById[topic.subjectId]!
                                    .shortName,
                                style: TextStyle(
                                  color: context.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (topic.niche != null)
                              Text(
                                'NICHE',
                                style: TextStyle(
                                  color: context.isDark
                                      ? JewteColors.lime
                                      : JewteColors.rust,
                                  fontSize: 9,
                                  letterSpacing: .6,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            if (topic.kind == 'supporting' ||
                                topic.kind == 'legacy')
                              Text(
                                topic.kind == 'legacy'
                                    ? 'LEGACY PYQ'
                                    : 'SUPPORTING',
                                style: TextStyle(
                                  color: context.muted,
                                  fontSize: 9,
                                  letterSpacing: .5,
                                ),
                              ),
                            if (saved)
                              Icon(
                                Icons.bookmark_rounded,
                                size: 12,
                                color: context.colors.primary,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onOpen,
                tooltip: 'Topic details and YouTube search',
                icon: Icon(
                  Icons.arrow_outward_rounded,
                  size: 18,
                  color: context.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });
  final IconData icon;
  final String title, description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 20),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.soft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 31, color: context.colors.primary),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: context.text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 9),
        Text(
          description,
          style: context.text.bodyMedium?.copyWith(color: context.muted),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? context.colors.primary : context.colors.surface,
    borderRadius: BorderRadius.circular(30),
    child: InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? context.colors.primary : context.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? context.colors.onPrimary : context.muted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? context.colors.onPrimary : context.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class OrbitArtwork extends StatelessWidget {
  const OrbitArtwork({super.key});
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(120, 160), painter: _OrbitPainter());
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width * .61, s.height * .52);
    c.rotate(-.45);
    for (var i = 0; i < 3; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = JewteColors.lime.withValues(alpha: .24 + i * .1);
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 55 + i * 36, height: 120),
        p,
      );
    }
    c.drawCircle(const Offset(36, -45), 5, Paint()..color = JewteColors.lime);
    c.drawCircle(
      const Offset(-30, 50),
      3,
      Paint()..color = const Color(0xFF89AF90),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => false;
}
