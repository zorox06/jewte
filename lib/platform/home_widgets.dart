import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WidgetDestination {
  const WidgetDestination(this.kind, this.topicId);
  final String kind;
  final String? topicId;
  factory WidgetDestination.fromJson(Map<Object?, Object?> json) =>
      WidgetDestination(
        json['kind'] as String? ?? 'library',
        json['topicId'] as String?,
      );
}

/// Android widgets are a read-only view of study progress. Flutter remains the
/// single writer of the user's checklist, so widget taps cannot overwrite it.
class HomeWidgetBridge {
  HomeWidgetBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('app.jewte/widgets');
  final MethodChannel _channel;
  final _destinations = StreamController<WidgetDestination>.broadcast();
  Stream<WidgetDestination> get destinations => _destinations.stream;
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Timer? _syncTimer;
  Map<String, Object?>? _latest;
  Future<void> _queue = Future.value();
  bool _disposed = false;

  void initialize() {
    if (!supported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'launchAction') await takeLaunchAction();
    });
  }

  Future<void> takeLaunchAction() async {
    if (!supported || _disposed) return;
    try {
      final action = await _channel.invokeMapMethod<Object?, Object?>(
        'takeLaunchAction',
      );
      if (action != null && !_disposed) {
        _destinations.add(WidgetDestination.fromJson(action));
      }
    } on PlatformException {
      /* Normal app launch remains usable. */
    }
  }

  void scheduleSync(Map<String, Object?> snapshot) {
    if (!supported || _disposed) return;
    _latest = Map.of(snapshot);
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 180), flush);
  }

  Future<void> flush() async {
    _syncTimer?.cancel();
    final snapshot = _latest;
    _latest = null;
    if (!supported || _disposed) return;
    if (snapshot == null) return _queue;
    _queue = _queue.then((_) async {
      try {
        await _channel.invokeMethod<void>('syncProgress', jsonEncode(snapshot));
      } on PlatformException {
        /* A launcher failure must not affect saved study data. */
      }
    });
    await _queue;
  }

  Future<bool> requestPin(String kind) async => supported
      ? await _channel.invokeMethod<bool>('requestPin', {'kind': kind}) ?? false
      : false;
  Future<Uint8List?> preview(
    String kind, {
    int width = 720,
    int height = 360,
  }) async => supported
      ? _channel.invokeMethod<Uint8List>('renderPreview', {
          'kind': kind,
          'width': width,
          'height': height,
        })
      : null;
  Future<Map<String, Object?>> info() async => supported
      ? Map<String, Object?>.from(
          await _channel.invokeMapMethod<String, Object?>('widgetInfo') ?? {},
        )
      : {'supported': false, 'progressCount': 0, 'topicCount': 0};
  void dispose() {
    _disposed = true;
    _syncTimer?.cancel();
    if (supported) _channel.setMethodCallHandler(null);
    _destinations.close();
  }
}
