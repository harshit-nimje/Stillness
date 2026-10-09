import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/stillness_store.dart';
import '../models/stillness_data.dart';

/// A transient toast (the web app's `#say` popover). [actionLabel] renders the
/// inline underlined button ("Undo", "Restore", ...).
class ToastMsg {
  final int id;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  ToastMsg(this.id, this.text, {this.actionLabel, this.onAction});
}

class ParsedTask {
  final String title;
  final String? tag;
  final String? due;
  final String? rec;
  ParsedTask(this.title, this.tag, this.due, this.rec);
}

/// Central application state: the persisted document plus every transient
/// piece of list/day/settings behaviour from the original script.
class AppState extends ChangeNotifier {
  AppState(this.d) {
    today = ymd(DateTime.now());
  }

  StillnessData d;

  /// Today's date as yyyy-mm-dd (rolls over at midnight).
  late String today;

  // ---- transient list UI state ----
  bool expand = false;
  String? scope; // tag filter
  String? fresh; // last-added task id (for the rise-in animation)
  final Set<String> ling = {}; // ids kept visible briefly after completion

  // ---- day ritual ----
  final List<String> pend = []; // tasks staged in the morning sheet

  // ---- toast ----
  final ValueNotifier<ToastMsg?> toast = ValueNotifier(null);
  int _toastSeq = 0;
  Timer? _toastTimer;

  // ---- platform prefs ----
  bool reduceMotion = false;
  bool storageWarned = false;

  final Random _rnd = Random();

  // -------------------------------------------------------------------------
  // Persistence
  // -------------------------------------------------------------------------
  bool _saveScheduled = false;

  Future<void> save() async {
    d.u = DateTime.now().millisecondsSinceEpoch;
    if (_saveScheduled) return;
    _saveScheduled = true;
    // Micro-debounce: coalesce rapid edits into one write, like a rAF batch.
    await Future<void>.delayed(Duration.zero);
    _saveScheduled = false;
    final ok = await StillnessStore.save(d);
    if (!ok && !storageWarned) {
      storageWarned = true;
      say("This device can't save. Copy a backup in Settings.");
    }
  }

  // -------------------------------------------------------------------------
  // Theme / time helpers
  // -------------------------------------------------------------------------
  bool isDark(DateTime now) {
    if (d.theme == 'dark') return true;
    if (d.theme == 'light') return false;
    // 'auto' → follow the system's brightness, supplied by the platform.
    return _systemDark;
  }

  bool _systemDark = false;
  set systemDark(bool v) {
    if (_systemDark == v) return;
    _systemDark = v;
    notifyListeners();
  }

  static bool isNight(DateTime now) {
    final h = now.hour + now.minute / 60;
    return h < 5.5 || h >= 20;
  }

  int sessionsToday() => d.log.where((e) => e.date == today).length;

  /// A task is visible if it has no hide-date or that date has arrived.
  bool vis(TaskItem t) => t.on == null || t.on!.compareTo(today) <= 0;

  // -------------------------------------------------------------------------
  // Greeting / date / note
  // -------------------------------------------------------------------------
  String greeting() {
    final h = DateTime.now().hour;
    final g = h < 5
        ? 'Still awake'
        : h < 12
            ? 'Good morning'
            : h < 17
                ? 'Good afternoon'
                : 'Good evening';
    return d.name.isNotEmpty ? '$g, ${d.name}.' : '$g.';
  }

  String dateLine() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final n = DateTime.now();
    return '${days[n.weekday - 1]} ${n.day} ${months[n.month - 1]}';
  }

  static const _calm = [
    'Nothing here needs to be finished all at once.',
    'Slow is a pace, too.',
    'One thing, then the next.',
    'You can stop whenever you need to.',
    'Rest is part of the work.',
    'The list will wait.',
  ];
  static const _praise = [
    'Done.',
    'One breath lighter.',
    'Quietly accomplished.',
    'That counts.',
    'Well done. Breathe.',
  ];

  String pickNote() {
    final j = d.joy.length > 40 ? d.joy.sublist(d.joy.length - 40) : d.joy;
    final p = (j.isNotEmpty && _rnd.nextDouble() < .6) ? j[_rnd.nextInt(j.length)] : null;
    return p != null ? 'A good thing you noted: \u201C${p.text}\u201D' : _calm[_rnd.nextInt(_calm.length)];
  }

  // -------------------------------------------------------------------------
  // Task parsing / mutation
  // -------------------------------------------------------------------------
  ParsedTask parse(String v) {
    String? tag, due, rec;
    v = v.replaceFirstMapped(RegExp(r'(^|\s)#(\w+)'), (m) {
      tag = m[2]!.toLowerCase();
      return m[1]!;
    });
    v = v.replaceFirstMapped(
        RegExp(r'(^|\s)@(\d{1,2})(?::(\d{2}))?\s?(am|pm)?\b', caseSensitive: false), (m) {
      var h = int.parse(m[2]!);
      final mi = m[3];
      final ap = m[4]?.toLowerCase();
      if (ap != null) {
        if (ap == 'pm' && h < 12) h += 12;
        if (ap == 'am' && h == 12) h = 0;
      }
      if (h < 24 && (mi == null || int.parse(mi) < 60)) {
        due = '${h.toString().padLeft(2, '0')}:${mi ?? '00'}';
      }
      return m[1]!;
    });
    v = v.replaceFirstMapped(RegExp(r'(^|\s)\*(daily|weekly)\b', caseSensitive: false), (m) {
      rec = m[2]![0].toLowerCase();
      return m[1]!;
    });
    return ParsedTask(v.trim(), tag, due, rec);
  }

  String hintFor(String v) {
    final p = parse(v);
    final a = <String>[];
    if (p.tag != null) a.add('tag #${p.tag}');
    if (p.due != null) a.add('at ${p.due}');
    if (p.rec != null) a.add('repeats ${p.rec == 'd' ? 'daily' : 'weekly'}');
    return a.join(', ');
  }

  /// Adds a task from raw text. Returns false when the list is full.
  bool addRaw(String v) {
    final p = parse(v);
    if (p.title.isEmpty) return false;
    if (d.tasks.length >= 500) {
      say('The list is full. Clear a few tasks first.');
      return false;
    }
    final t = TaskItem(id: uid(), title: p.title, tag: p.tag, due: p.due, rec: p.rec);
    d.tasks.add(t);
    fresh = t.id;
    return true;
  }

  /// `spawn()` — create the next occurrence of a recurring task.
  void _spawn(TaskItem t) {
    if (t.rec == null || t.sp != null) return;
    final n = TaskItem(
      id: uid(),
      title: t.title,
      tag: t.tag,
      due: t.due,
      rec: t.rec,
      on: ymd(DateTime.now().add(Duration(days: t.rec == 'w' ? 7 : 1))),
    );
    t.sp = n.id;
    d.tasks.add(n);
  }

  void _unspawn(TaskItem t) {
    if (t.sp != null) {
      d.tasks.removeWhere((x) => x.id == t.sp);
      t.sp = null;
    }
  }

  void complete(TaskItem t) {
    t.done = true;
    _spawn(t);
    final all = visibleTasks().every((x) => x.done);
    d.bank += 5;
    ling.add(t.id);
    say(all ? 'Everything done. Rest well.' : _praise[_rnd.nextInt(_praise.length)]);
    Timer(const Duration(milliseconds: 2400), () {
      ling.remove(t.id);
      notifyListeners();
    });
    save();
    notifyListeners();
    onTaskCompleted?.call(all, t);
  }

  /// Called by the UI to fire the ring + chime + haptic. (all done?, task)
  void Function(bool allDone, TaskItem t)? onTaskCompleted;

  /// Called when a row's "focus on this task" action is used.
  void Function(TaskItem t)? onFocusTask;

  void uncomplete(TaskItem t) {
    t.done = false;
    d.bank = max(0, d.bank - 5);
    _unspawn(t);
    ling.remove(t.id);
    save();
    notifyListeners();
  }

  void removeTask(TaskItem t) {
    final i = d.tasks.indexOf(t);
    if (i < 0) return;
    d.tasks.removeAt(i);
    ling.remove(t.id);
    save();
    notifyListeners();
    say('Task removed.', actionLabel: 'Undo', onAction: () {
      d.tasks.insert(min(i, d.tasks.length), t);
      save();
      notifyListeners();
    });
  }

  void pinTask(TaskItem t) {
    d.tasks.remove(t);
    d.tasks.insert(0, t);
    save();
    notifyListeners();
  }

  void updateTask(TaskItem t, String value) {
    final p = parse(value);
    if (p.title.isEmpty) return;
    t.title = p.title;
    if (p.tag != null) t.tag = p.tag;
    if (p.due != null) {
      t.due = p.due;
      t.rd = null;
    }
    if (p.rec != null) t.rec = p.rec;
    save();
    notifyListeners();
  }

  void reorder(TaskItem a, TaskItem b) {
    final ia = d.tasks.indexOf(a), ib = d.tasks.indexOf(b);
    if (ia < 0 || ib < 0) return;
    final tmp = d.tasks[ia];
    d.tasks[ia] = d.tasks[ib];
    d.tasks[ib] = tmp;
    save();
    notifyListeners();
  }

  List<TaskItem> visibleTasks() => d.tasks.where(vis).toList();

  /// Open (undone) tasks honouring the tag scope.
  List<TaskItem> openTasks() {
    final v = visibleTasks();
    return v.where((t) => !t.done && (scope == null || t.tag == scope)).toList();
  }

  /// Tasks shown in the main list (first 5 unless expanded or scoped).
  List<TaskItem> shownOpen() {
    final open = openTasks();
    return (expand || scope != null) ? open : open.take(5).toList();
  }

  List<TaskItem> doneToday() =>
      visibleTasks().where((t) => t.done && !ling.contains(t.id)).toList();

  TaskItem? byId(String? id) {
    if (id == null) return null;
    for (final t in d.tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  void toggleScope(String tag) {
    scope = scope == tag ? null : tag;
    notifyListeners();
  }

  void toggleMore() {
    if (scope != null) {
      scope = null;
    } else {
      expand = !expand;
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Momentum / habits / time bank
  // -------------------------------------------------------------------------
  static String mday(int offset) =>
      ymd(DateTime.now().subtract(Duration(days: offset)));

  int hw(Habit h) => (h.kind == 'g' ? 10 : -12) * h.weight;

  MomentumResult momentum() {
    final fm = <String, int>{};
    for (final e in d.log) {
      fm[e.date] = (fm[e.date] ?? 0) + e.minutes;
    }
    double m = 0;
    final r = <double>[];
    for (int o = 13; o >= 0; o--) {
      final k = mday(o);
      m *= .9;
      double s = (fm[k] ?? 0) * .2;
      for (final id in (d.hd[k] ?? const <String>[])) {
        Habit? h;
        for (final x in d.h) {
          if (x.id == id) h = x;
        }
        if (h != null) s += hw(h);
      }
      m = max(0, m + s);
      r.add(m);
    }
    return MomentumResult(r, m.round(), (m - r[12]).round());
  }

  bool habitDoneToday(String id) => (d.hd[today] ?? const <String>[]).contains(id);

  void toggleHabit(Habit h) {
    final a = d.hd.putIfAbsent(today, () => <String>[]);
    final i = a.indexOf(h.id);
    final bn = h.kind == 'g' ? h.weight * 5 : 0;
    if (i < 0) {
      a.add(h.id);
      d.bank += bn;
      if (h.kind == 'g') onHabitDone?.call(h);
    } else {
      a.removeAt(i);
      d.bank = max(0, d.bank - bn);
    }
    save();
    notifyListeners();
  }

  void Function(Habit h)? onHabitDone;

  void addHabit(String name, String kind, int weight) {
    if (name.trim().isEmpty) return;
    if (d.h.length >= 30) {
      say('Habit limit reached.');
      return;
    }
    d.h.add(Habit(id: uid(), name: name.trim().substring(0, min(40, name.trim().length)), kind: kind, weight: weight));
    save();
    notifyListeners();
  }

  void removeHabit(Habit h) {
    d.h.remove(h);
    save();
    notifyListeners();
    say('Habit removed.', actionLabel: 'Undo', onAction: () {
      d.h.add(h);
      save();
      notifyListeners();
    });
  }

  void spendBank() {
    if (d.bank < 15) return;
    d.bank -= 15;
    save();
    notifyListeners();
    say('15 minutes spent. Enjoy them.');
  }

  // -------------------------------------------------------------------------
  // Focus log
  // -------------------------------------------------------------------------
  void logFocusSession(int minutes) {
    d.log.add(LogEntry(today, minutes));
    d.bank += (minutes / 2).round();
    save();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Settings
  // -------------------------------------------------------------------------
  void setConfig({double? focus, double? rest, double? longRest, bool? auto}) {
    if (focus != null) d.cfg.focus = focus;
    if (rest != null) d.cfg.rest = rest;
    if (longRest != null) d.cfg.longRest = longRest;
    if (auto != null) d.cfg.auto = auto;
    save();
    notifyListeners();
  }

  void setName(String name) {
    d.name = name.trim().substring(0, min(40, name.trim().length));
    save();
    notifyListeners();
  }

  void setTheme(String theme) {
    d.theme = theme;
    save();
    notifyListeners();
  }

  String statsLine() {
    final n = d.log.where((e) => e.date == today).toList();
    final mins = n.fold<int>(0, (a, e) => a + e.minutes);
    return 'Today: ${n.length} sessions, $mins minutes focused. All time: ${d.log.length} sessions.';
  }

  // -------------------------------------------------------------------------
  // Day ritual
  // -------------------------------------------------------------------------
  void beginDay({required String name, required List<String> dropIds, required List<String> newTasks, required String goodThing}) {
    if (name.trim().isNotEmpty) d.name = name.trim().substring(0, min(40, name.trim().length));
    d.tasks.removeWhere((t) => dropIds.contains(t.id));
    for (final v in newTasks) {
      addRaw(v);
    }
    if (goodThing.trim().isNotEmpty) {
      d.joy.add(Joy(today, goodThing.trim().substring(0, min(140, goodThing.trim().length))));
    }
    d.last = today;
    save();
    notifyListeners();
  }

  void markLast() {
    d.last = today;
    save();
  }

  // -------------------------------------------------------------------------
  // Onboarding
  // -------------------------------------------------------------------------
  void applyOnboarding({
    required String name,
    required Set<String> build,
    required Set<String> quit,
    required String firstTask,
  }) {
    if (name.trim().isNotEmpty) {
      d.name = name.trim().substring(0, min(40, name.trim().length));
    }
    for (final n in build) {
      if (d.h.length < 30) d.h.add(Habit(id: uid(), name: n.substring(0, min(40, n.length)), kind: 'g', weight: 2));
    }
    for (final n in quit) {
      if (d.h.length < 30) d.h.add(Habit(id: uid(), name: n.substring(0, min(40, n.length)), kind: 'b', weight: 2));
    }
    if (firstTask.trim().isNotEmpty) addRaw(firstTask);
  }

  // -------------------------------------------------------------------------
  // Backup / restore
  // -------------------------------------------------------------------------
  String backupText() => StillnessStore.backupText(d);

  bool restore(String text) {
    try {
      final prev = d;
      d = StillnessStore.parseBackup(text);
      save();
      notifyListeners();
      say('Restored.', actionLabel: 'Undo', onAction: () {
        d = prev;
        save();
        notifyListeners();
      });
      return true;
    } catch (_) {
      say('That is not a Stillness backup.');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Toasts
  // -------------------------------------------------------------------------
  void say(String msg, {String? actionLabel, VoidCallback? onAction}) {
    _toastSeq++;
    toast.value = ToastMsg(_toastSeq, msg, actionLabel: actionLabel, onAction: onAction);
    _toastTimer?.cancel();
    _toastTimer = Timer(Duration(milliseconds: onAction != null ? 5200 : 3200), () {
      toast.value = null;
    });
  }

  // -------------------------------------------------------------------------
  // Periodic rollover + reminders (the 20s interval in the original)
  // -------------------------------------------------------------------------
  Timer? _rollTimer;

  void startClock() {
    _rollTimer?.cancel();
    _rollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      final dNow = ymd(DateTime.now());
      if (dNow != today) {
        today = dNow;
        d.tasks.removeWhere((t) => t.done);
        save();
        notifyListeners();
        onDayRollover?.call();
      }
      _remind();
      notifyListeners();
    });
  }

  VoidCallback? onDayRollover;

  void _remind() {
    final now = DateTime.now();
    final hm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    int mm(String q) => int.parse(q.substring(0, 2)) * 60 + int.parse(q.substring(3));
    var ch = false;
    for (final t in d.tasks) {
      if (t.done || t.due == null || t.rd == today || !vis(t)) continue;
      if (t.due!.compareTo(hm) > 0) continue;
      if (mm(hm) - mm(t.due!) > 60) continue;
      t.rd = today;
      ch = true;
      say('Time for: ${t.title}');
    }
    if (ch) save();
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    _toastTimer?.cancel();
    toast.dispose();
    super.dispose();
  }
}

/// Momentum result: the 14-day series, today's score, and the delta vs yesterday.
class MomentumResult {
  final List<double> series;
  final int now;
  final int delta;
  MomentumResult(this.series, this.now, this.delta);
}
