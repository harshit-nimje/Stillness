import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_state.dart';

/// FOCUS — one timer, tied to a task. Phases run on absolute timestamps
/// (`endMs`), never by decrementing a counter, so backgrounding the app or
/// sleeping the device cannot skew them. Mirrors the original `T` object.
class FocusController extends ChangeNotifier {
  FocusController(this.app) {
    left = len('f');
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  final AppState app;

  String mode = 'f'; // 'f' | 'b' | 'l'
  double left = 0; // seconds remaining
  int endMs = 0; // absolute epoch ms when the current phase ends
  bool run = false;
  int n = 0; // completed focus sessions in this cycle (drives long rest)
  String? taskId;
  bool open = false;

  Timer? _timer;

  /// Fired when a phase completes (for the flash / chime / haptic).
  void Function(bool big)? onPhaseEnd;

  double len(String m) => app.d.cfg.len(m) * 60;

  /// 0..1 progress of an open focus session — drives the sky's sun path.
  double? get progress => open ? (1 - left / len(mode)).clamp(0.0, 1.0) : null;

  static String fmt(double s) {
    final v = s < 0 ? 0 : s.ceil();
    return '${v ~/ 60}:${(v % 60).toString().padLeft(2, '0')}';
  }

  void _tick() {
    if (run) {
      left = (endMs - DateTime.now().millisecondsSinceEpoch) / 1000;
      if (left <= 0) phaseEnd();
    }
    notifyListeners();
  }

  void openStage(String? id) {
    if (id != null) taskId = id;
    if (!run && left == len(mode)) {
      run = true;
      endMs = DateTime.now().millisecondsSinceEpoch + (left * 1000).round();
    }
    open = true;
    notifyListeners();
    onOpen?.call();
  }

  VoidCallback? onOpen;

  void closeStage() {
    open = false;
    notifyListeners();
  }

  void endSession() {
    run = false;
    mode = 'f';
    left = len('f');
    taskId = null;
    open = false;
    notifyListeners();
  }

  void toggleRun() {
    if (run) {
      run = false;
    } else {
      run = true;
      endMs = DateTime.now().millisecondsSinceEpoch + (left * 1000).round();
    }
    notifyListeners();
  }

  void phaseEnd() {
    onPhaseEnd?.call(mode == 'f');
    if (mode == 'f') {
      n++;
      app.logFocusSession(app.d.cfg.focus.round());
      mode = (n % 4 != 0) ? 'b' : 'l';
    } else {
      mode = 'f';
    }
    left = len(mode);
    run = app.d.cfg.auto;
    if (run) endMs = DateTime.now().millisecondsSinceEpoch + (left * 1000).round();
    final msg = mode == 'f'
        ? 'Ready when you are.'
        : mode == 'l'
            ? 'A long rest. Well earned.'
            : 'Time to rest your eyes.';
    app.say(msg);
    notifyListeners();
  }

  /// Called when the config changes so an idle timer picks up the new length.
  void syncFromConfig() {
    if (!run) left = len(mode);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
