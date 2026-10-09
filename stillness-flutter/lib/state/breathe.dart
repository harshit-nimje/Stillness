import 'dart:async';

import 'package:flutter/foundation.dart';

import '../sky/sky_painter.dart';

/// BREATHE — the three patterns and the running phase label / countdown.
/// The circle itself is drawn by the sky painter from `elapsedSeconds`; this
/// controller supplies the text the original wrote into `#bl` / `#bn`.
class BreatheController extends ChangeNotifier {
  bool on = false;
  String kind = 'box';
  DateTime? _t0;

  String label = 'Breathe in';
  int count = 4;

  Timer? _timer;

  /// seconds since the session began (performance.now()/1000 analog)
  double get elapsedSeconds =>
      _t0 == null ? 0 : DateTime.now().difference(_t0!).inMilliseconds / 1000;

  void setBreath(bool on, {String? k}) {
    this.on = on;
    if (k != null) kind = k;
    _t0 = DateTime.now();
    _recompute();
    notifyListeners();
    _timer?.cancel();
    if (on) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _recompute();
        notifyListeners();
      });
    }
  }

  void _recompute() {
    final P = breathePattern(kind);
    final tot = P.fold<double>(0, (a, b) => a + b.len);
    double t = elapsedSeconds % tot;
    int i = 0;
    while (t >= P[i].len) {
      t -= P[i].len;
      i++;
    }
    label = P[i].label;
    count = (P[i].len - t).ceil();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
