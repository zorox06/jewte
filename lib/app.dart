import 'dart:async';

import 'package:flutter/material.dart';

import 'models/catalog.dart';
import 'state/study_store.dart';
import 'theme.dart';
import 'widgets.dart';
import 'screens/home_shell.dart';
import 'screens/topic_detail.dart';
import 'platform/home_widgets.dart';

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  StudyStore? store;
  final homeWidgets = HomeWidgetBridge();
  String? error;
  @override
  void initState() {
    super.initState();
    homeWidgets.initialize();
    load();
  }

  Future<void> load() async {
    setState(() => error = null);
    try {
      final catalog = await Catalog.load();
      final loaded = StudyStore(
        catalog,
        DeviceProgressRepository(),
        homeWidgets: homeWidgets,
      );
      await loaded.load();
      if (mounted) setState(() => store = loaded);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Your study space could not be opened. Your saved data has not been changed.',
        );
      }
    }
  }

  @override
  void dispose() {
    store?.dispose();
    homeWidgets.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (store != null) return JewteApp(store: store!);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jewte',
      theme: jewteTheme(false),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Brand(large: true),
                const SizedBox(height: 30),
                if (error == null)
                  const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  FilledButton(onPressed: load, child: const Text('Try again')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JewteApp extends StatefulWidget {
  const JewteApp({super.key, required this.store});
  final StudyStore store;
  @override
  State<JewteApp> createState() => _JewteAppState();
}

class _JewteAppState extends State<JewteApp> with WidgetsBindingObserver {
  final navigator = GlobalKey<NavigatorState>();
  final shell = GlobalKey<HomeShellState>();
  late final lightTheme = jewteTheme(false);
  late final darkTheme = jewteTheme(true);
  late bool dark, reduceMotion;
  StreamSubscription<WidgetDestination>? subscription;
  StudyStore get store => widget.store;
  @override
  void initState() {
    super.initState();
    dark = store.dark;
    reduceMotion = store.reduceMotion;
    store.addListener(preferencesChanged);
    WidgetsBinding.instance.addObserver(this);
    subscription = store.homeWidgets?.destinations.listen(openDestination);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => store.homeWidgets?.takeLaunchAction(),
    );
  }

  void preferencesChanged() {
    if (dark != store.dark || reduceMotion != store.reduceMotion) {
      setState(() {
        dark = store.dark;
        reduceMotion = store.reduceMotion;
      });
    }
  }

  void openDestination(WidgetDestination destination) {
    if (!mounted || navigator.currentState == null) return;
    navigator.currentState!.popUntil((route) => route.isFirst);
    if (destination.kind == 'topic') {
      final topic = store.catalog.byId[destination.topicId];
      if (topic != null) openTopic(shell.currentContext!, store, topic);
    } else {
      shell.currentState?.navigate(1);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) store.homeWidgets?.flush();
  }

  @override
  void dispose() {
    store.removeListener(preferencesChanged);
    subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    debugShowCheckedModeBanner: false,
    title: 'Jewte',
    theme: lightTheme,
    darkTheme: darkTheme,
    themeMode: store.dark ? ThemeMode.dark : ThemeMode.light,
    themeAnimationDuration: Duration(
      milliseconds:
          store.reduceMotion ||
              WidgetsBinding
                  .instance
                  .platformDispatcher
                  .accessibilityFeatures
                  .disableAnimations
          ? 0
          : 220,
    ),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      final reduced = store.reduceMotion || media.disableAnimations;
      return MediaQuery(
        data: media.copyWith(disableAnimations: reduced),
        child: child!,
      );
    },
    home: HomeShell(key: shell, store: store),
  );
}
