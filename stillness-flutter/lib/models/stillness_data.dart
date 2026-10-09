import 'dart:math';

/// Faithful port of the original `clean()` / `store` data layer.
///
/// The web app stores a single versioned document under `stillness.v2`, and
/// migrates from `stillness.v1`. Every field is validated and clamped on load
/// and on import — "Never trust storage or an import." We keep the exact same
/// JSON key names so a backup produced by the web app restores here and vice
/// versa.

const String kStorageKey = 'stillness.v2';
const String kLegacyKey = 'stillness.v1';

String _pad2(int n) => n.toString().padLeft(2, '0');

/// `ymd()` — local calendar date as yyyy-mm-dd.
String ymd(DateTime d) => '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}';

final Random _rnd = Random();

/// `uid()` — base36 timestamp + 4 random chars.
String uid() {
  final base = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final tail = _rnd.nextInt(1 << 20).toRadixString(36).padLeft(4, '0');
  return (base + tail).substring(0, min(24, base.length + tail.length));
}

// ---------------------------------------------------------------------------
// Model pieces
// ---------------------------------------------------------------------------

class TaskItem {
  String id;
  String title; // t
  bool done;
  String? tag;
  String? due; // "HH:MM"
  String? rec; // 'd' | 'w'
  String? on; // yyyy-mm-dd (hidden until this date — spawned recurrences)
  String? sp; // id of the spawned successor
  String? rd; // date this task last reminded

  TaskItem({
    required this.id,
    required this.title,
    this.done = false,
    this.tag,
    this.due,
    this.rec,
    this.on,
    this.sp,
    this.rd,
  });

  TaskItem copy() => TaskItem(
        id: id,
        title: title,
        done: done,
        tag: tag,
        due: due,
        rec: rec,
        on: on,
        sp: sp,
        rd: rd,
      );

  static TaskItem? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final t = _str(raw['t'], 120);
    if (t.trim().isEmpty) return null;
    final due = raw['due'];
    final rec = raw['rec'];
    return TaskItem(
      id: _str(raw['id'], 24).isEmpty ? uid() : _str(raw['id'], 24),
      title: t,
      done: raw['done'] == true,
      tag: _str(raw['tag'], 24).isEmpty ? null : _str(raw['tag'], 24),
      due: (due is String && RegExp(r'^\d\d:\d\d$').hasMatch(due)) ? due : null,
      rec: (rec == 'd' || rec == 'w') ? rec as String : null,
      on: _str(raw['on'], 10).isEmpty ? null : _str(raw['on'], 10),
      sp: _str(raw['sp'], 24).isEmpty ? null : _str(raw['sp'], 24),
      rd: _str(raw['rd'], 10).isEmpty ? null : _str(raw['rd'], 10),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        't': title,
        'done': done,
        if (tag != null) 'tag': tag,
        if (due != null) 'due': due,
        if (rec != null) 'rec': rec,
        if (on != null) 'on': on,
        if (sp != null) 'sp': sp,
        if (rd != null) 'rd': rd,
      };
}

class LogEntry {
  final String date; // yyyy-mm-dd
  final int minutes;
  LogEntry(this.date, this.minutes);

  static LogEntry? fromJson(dynamic raw) {
    if (raw is List && raw.isNotEmpty && raw[0] is String) {
      return LogEntry((raw[0] as String).substring(0, min(10, (raw[0] as String).length)),
          _num(raw.length > 1 ? raw[1] : null, 1, 180, 25).round());
    }
    return null;
  }

  List<dynamic> toJson() => [date, minutes];
}

class Joy {
  final String date;
  final String text;
  Joy(this.date, this.text);

  static Joy? fromJson(dynamic raw) {
    if (raw is Map && raw['t'] is String) {
      return Joy(_str(raw['d'], 10), _str(raw['t'], 140));
    }
    return null;
  }

  Map<String, dynamic> toJson() => {'d': date, 't': text};
}

class Habit {
  String id;
  String name; // n
  String kind; // 'g' build | 'b' quit
  int weight; // 1..3
  Habit({required this.id, required this.name, this.kind = 'g', this.weight = 2});

  /// `hw()` — a build habit is worth +10/level, a quit habit −12/level.
  int get score => (kind == 'g' ? 10 : -12) * weight;

  static Habit? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final n = _str(raw['n'], 40);
    if (n.trim().isEmpty) return null;
    return Habit(
      id: _str(raw['id'], 24).isEmpty ? uid() : _str(raw['id'], 24),
      name: n,
      kind: raw['k'] == 'b' ? 'b' : 'g',
      weight: _num(raw['w'], 1, 3, 2).round(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'n': name, 'k': kind, 'w': weight};
}

class FocusConfig {
  double focus; // f — minutes, 5..60
  double rest; // b — 1..30
  double longRest; // l — 10..45
  bool auto; // auto-start next session

  FocusConfig({this.focus = 25, this.rest = 5, this.longRest = 15, this.auto = false});

  static FocusConfig fromJson(dynamic raw) {
    final c = raw is Map ? raw : const {};
    return FocusConfig(
      focus: _num(c['f'], 5, 60, 25).toDouble(),
      rest: _num(c['b'], 1, 30, 5).toDouble(),
      longRest: _num(c['l'], 10, 45, 15).toDouble(),
      auto: c['auto'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'f': focus, 'b': rest, 'l': longRest, 'auto': auto};

  double len(String mode) =>
      mode == 'f' ? focus : mode == 'b' ? rest : longRest;
}

/// The whole persisted document.
class StillnessData {
  int v = 2;
  String name = '';
  String last = '';
  String theme = 'auto'; // 'auto' | 'light' | 'dark'
  FocusConfig cfg = FocusConfig();
  List<TaskItem> tasks = [];
  List<LogEntry> log = [];
  List<Joy> joy = [];
  List<Habit> h = [];
  Map<String, List<String>> hd = {};
  double bank = 0;
  int u = 0; // updated-at millis (last-writer-wins across devices)
  bool ob = false; // onboarding complete

  StillnessData();

  /// `clean(d)` — validate, clamp, migrate. Never throws.
  factory StillnessData.clean(dynamic raw) {
    final d = (raw is Map) ? raw : const <String, dynamic>{};
    final s = StillnessData();

    s.name = _str(d['name'], 40);
    s.last = _str(d['last'], 10);
    s.theme = (d['theme'] == 'light' || d['theme'] == 'dark') ? d['theme'] as String : 'auto';
    s.cfg = FocusConfig.fromJson(d['cfg']);

    final rawTasks = d['tasks'];
    if (rawTasks is List) {
      for (final t in rawTasks.take(500)) {
        final task = TaskItem.fromJson(t);
        if (task != null) s.tasks.add(task);
      }
    }

    final rawLog = d['log'];
    if (rawLog is List) {
      final start = rawLog.length > 3000 ? rawLog.length - 3000 : 0;
      for (final e in rawLog.sublist(start)) {
        final le = LogEntry.fromJson(e);
        if (le != null) s.log.add(le);
      }
    }

    final rawJoy = d['joy'];
    if (rawJoy is List) {
      final start = rawJoy.length > 200 ? rawJoy.length - 200 : 0;
      for (final j in rawJoy.sublist(start)) {
        final jo = Joy.fromJson(j);
        if (jo != null) s.joy.add(jo);
      }
    }

    final rawH = d['h'];
    if (rawH is List) {
      for (final x in rawH.take(30)) {
        final hb = Habit.fromJson(x);
        if (hb != null) s.h.add(hb);
      }
    }

    final rawHd = d['hd'];
    if (rawHd is Map) {
      final keys = rawHd.keys.toList();
      final start = keys.length > 120 ? keys.length - 120 : 0;
      for (final k in keys.sublist(start)) {
        if (k is String && RegExp(r'^\d{4}-\d\d-\d\d$').hasMatch(k)) {
          final val = rawHd[k];
          if (val is List) {
            s.hd[k] = val.take(30).map((x) => _str(x, 24)).toList();
          }
        }
      }
    }

    s.bank = _num(d['bank'], 0, 1e6, 0).toDouble();
    s.u = _num(d['u'], 0, 1e15, 0).round();

    final hadData = s.name.isNotEmpty ||
        s.last.isNotEmpty ||
        (rawTasks is List && rawTasks.isNotEmpty) ||
        (rawLog is List && rawLog.isNotEmpty) ||
        (rawH is List && rawH.isNotEmpty);
    s.ob = d['ob'] == true || hadData;

    return s;
  }

  Map<String, dynamic> toJson() => {
        'v': v,
        'name': name,
        'last': last,
        'theme': theme,
        'cfg': cfg.toJson(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'log': log.map((e) => e.toJson()).toList(),
        'joy': joy.map((j) => j.toJson()).toList(),
        'h': h.map((x) => x.toJson()).toList(),
        'hd': hd,
        'bank': bank,
        'u': u,
        'ob': ob,
      };
}

// ---------------------------------------------------------------------------
// Coercion helpers matching the JS `str` / `num`
// ---------------------------------------------------------------------------

String _str(dynamic v, int n) =>
    v is String ? v.substring(0, min(n, v.length)) : '';

num _num(dynamic v, num a, num b, num fallback) {
  if (v == null || v == '') return fallback;
  if (v is num && v.isFinite) return v < a ? a : (v > b ? b : v);
  if (v is String) {
    final p = num.tryParse(v);
    if (p != null && p.isFinite) return p < a ? a : (p > b ? b : p);
  }
  return fallback;
}
