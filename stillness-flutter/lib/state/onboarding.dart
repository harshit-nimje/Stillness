import 'package:flutter/foundation.dart';

/// ONBOARDING — first run only. Answers are held here and applied to the
/// document once the person picks how to continue, exactly like `OB`.
class OnboardingController extends ChangeNotifier {
  int i = 0;
  int d = 1; // direction, drives the slide-in
  int rep = 0; // replay mode (short flow: 0..3)
  String name = '';
  String task = '';
  bool hear = false; // "Hear Dawn" preview playing

  final List<String> bl = [
    'Sleep earlier', 'Move daily', 'Read 10 pages', 'Study', 'Meditate',
    'Drink water', 'Eat well', 'Create something', 'Save money',
  ];
  final List<String> ql = [
    'Doomscrolling', 'Late nights', 'Sugar', 'Smoking', 'Caffeine',
    'Procrastinating', 'Binge gaming', 'Nail biting',
  ];
  final Set<String> bs = {};
  final Set<String> qs = {};

  int get lastPage => rep == 1 ? 3 : 8;

  void go(int n, int dir) {
    i = n;
    d = dir;
    notifyListeners();
  }

  void next() {
    if (rep == 1 && i == 3) return;
    if (i < 8) go(i + 1, 1);
  }

  void back() {
    if (i > 0) go(i - 1, -1);
  }

  void toggle(List<String> pool, Set<String> set, String v) {
    if (set.contains(v)) {
      set.remove(v);
    } else {
      set.add(v);
    }
    notifyListeners();
  }

  void addCustom(List<String> pool, Set<String> set, String v) {
    final t = v.trim();
    if (t.isEmpty) return;
    if (!pool.contains(t)) pool.add(t);
    set.add(t);
    notifyListeners();
  }

  void reset({required int rep}) {
    this.rep = rep;
    i = 0;
    d = 1;
    notifyListeners();
  }
}
