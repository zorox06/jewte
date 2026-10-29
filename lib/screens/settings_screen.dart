import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/study_store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home_widgets_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});
  final StudyStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 7, 22, 35),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Make yourself at home.',
                  style: context.text.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'A few things you can make your own.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.muted,
                  ),
                ),
                const SectionTitle('Appearance'),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Dark appearance',
                    style: context.text.titleMedium,
                  ),
                  subtitle: const Text('Forest, carbon and a softer contrast.'),
                  value: store.dark,
                  onChanged: store.setDark,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Reduce motion', style: context.text.titleMedium),
                  subtitle: const Text('Keep transitions simple and still.'),
                  value: store.reduceMotion,
                  onChanged: store.setReduceMotion,
                ),
                const SectionTitle('Home screen'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.widgets_outlined),
                  title: const Text('Home-screen widgets'),
                  subtitle: const Text(
                    'Your progress and next concept, at a glance.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeWidgetsScreen(store: store),
                    ),
                  ),
                ),
                const SectionTitle('Your progress'),
                Text(
                  'Progress and notes stay on this device. Copy a backup before uninstalling or changing phones.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.muted,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: store.exportBackup()),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Backup copied. Paste it somewhere safe to keep it.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text('Copy progress backup'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => showImport(context),
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Restore from backup'),
                ),
                const SectionTitle('Inside Jewte'),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Brand(),
                      const SizedBox(height: 17),
                      Text(
                        '${store.catalog.topics.length} canonical concepts\n10 technical subjects\n${store.catalog.topics.where((t) => t.niche != null).length} curated niche PYQ topics',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No accounts, ads, analytics or study deadlines. The checklist works offline; YouTube searches open outside the app and need internet access.',
                        style: context.text.bodyMedium?.copyWith(
                          color: context.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Core · expands the supplied technical syllabus.\nSupporting · useful prerequisite or extension.\nLegacy PYQ · older coverage beyond explicit syllabus wording.',
                        style: context.text.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: context.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionTitle('Sources and design'),
                Text(
                  'Coverage: supplied CS_GATE2027_Syllabus.pdf, technical sections 2–10, and your 775-page PYQ compilation. Mathematics and aptitude are excluded. References use PDF viewer page numbers, not printed page numbers. The niche collection identifies question patterns, not future frequency predictions; supplied answer keys are not independently validated.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Layout adapted from TypeUI’s free Application Shell With Toolbar prompt.\nhttps://www.typeui.sh/prompts/shells\nOriginal Jewte palette: Paper · Carbon · Forest · Chartreuse.\nManrope and DM Serif Display: SIL Open Font License.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 22),
                const Eyebrow('JEWTE / VERSION 1.1.0'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> showImport(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ImportDialog(store: store),
    );
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.store});
  final StudyStore store;
  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final input = TextEditingController();
  String? error;
  bool busy = false;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Restore your progress'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste your Jewte backup. Restoring replaces the current progress and notes on this device.',
          ),
          const SizedBox(height: 15),
          TextField(
            controller: input,
            maxLines: 6,
            maxLength: 2000000,
            decoration: InputDecoration(
              hintText: 'Paste backup JSON…',
              errorText: error,
              counterText: '',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: busy
            ? null
            : () async {
                setState(() => busy = true);
                try {
                  await widget.store.importBackup(input.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Progress restored.')),
                    );
                  }
                } on FormatException catch (e) {
                  if (mounted) {
                    setState(() {
                      busy = false;
                      error = e.message;
                    });
                  }
                } catch (_) {
                  if (mounted) {
                    setState(() {
                      busy = false;
                      error = 'Could not restore this backup.';
                    });
                  }
                }
              },
        child: const Text('Restore'),
      ),
    ],
  );
}
