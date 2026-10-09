import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/type.dart';
import '../models/stillness_data.dart';
import '../state/app_state.dart';
import '../state/focus.dart';
import '../theme/theme_scope.dart';
import '../widgets/controls.dart';
import '../widgets/glass.dart';
import '../widgets/icons.dart';
import '../widgets/logo.dart';
import '../widgets/task_row.dart';
import 'focus_stage.dart';

/// The home view: greeting header, the task panel (list + add + done), and the
/// closing note. When a focus session is open the stage replaces this entirely,
/// exactly like `.focusing .home { display: none }`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Tokens.ease,
      child: focus.open ? const FocusStage(key: ValueKey('stage')) : const _HomeBody(key: ValueKey('home')),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody({super.key});

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final _add = TextEditingController();
  String _hint = '';
  bool _doneOpen = false;

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final app = context.watch<AppState>();

    final open = app.shownOpen();
    final allOpen = app.openTasks();
    final done = app.doneToday();
    final v = app.visibleTasks();
    final tally = _tally(app, v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- header ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Logo(),
              Text(app.dateLine(), style: Type.body(p.ink2)),
              const SizedBox(height: 4),
              Text(app.greeting(), style: Type.h1(context, p.ink)),
              if (tally.isNotEmpty) Text(tally, style: Type.body(p.ink2)),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ---- panel ----
        Glass(
          palette: p,
          radius: Tokens.rPanel,
          child: Column(
            children: [
              for (int i = 0; i < open.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: p.line),
                TaskRow(task: open[i], isFresh: open[i].id == app.fresh),
              ],
              if (open.isEmpty && v.isEmpty && app.scope == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
                  child: Text('Nothing yet. Add the one thing that would make today good.',
                      style: Type.empty(p.ink2)),
                ),
              if (allOpen.length > 5 || app.scope != null)
                GestureDetector(
                  onTap: app.toggleMore,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: p.line, width: 1)),
                    ),
                    child: Text(
                      app.scope != null
                          ? 'Showing #${app.scope}. Show all tasks'
                          : app.expand
                              ? 'Show fewer'
                              : '${allOpen.length - 5} more',
                      style: Type.meta(p.ink2),
                    ),
                  ),
                ),
              // ---- add ----
              Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line, width: 1))),
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _add,
                        maxLength: 120,
                        style: Type.addInput(p.ink),
                        cursorColor: p.ac,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          counterText: '',
                          isDense: true,
                          hintText: 'Add a task',
                          hintStyle: Type.addInput(p.ink2),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.fromLTRB(22, 18, 12, 18),
                        ),
                        onChanged: (val) => setState(() => _hint = val.isEmpty ? '' : app.hintFor(val)),
                        onSubmitted: (val) {
                          if (val.trim().isEmpty) return;
                          app.addRaw(val);
                          _add.clear();
                          setState(() => _hint = '');
                          app.save();
                        },
                      ),
                    ),
                    IconBtn(body: Icons24.plus, onTap: () {
                      if (_add.text.trim().isEmpty) return;
                      app.addRaw(_add.text);
                      _add.clear();
                      setState(() => _hint = '');
                      app.save();
                    }),
                  ],
                ),
              ),
              if (_hint.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                  child: Align(alignment: Alignment.centerLeft, child: Text(_hint, style: Type.meta(p.ink2))),
                ),
              // ---- done ----
              if (done.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => setState(() => _doneOpen = !_doneOpen),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line, width: 1))),
                    child: Text('Done today, ${done.length}', style: Type.meta(p.ink2)),
                  ),
                ),
                if (_doneOpen)
                  for (final t in done)
                    TaskRow(task: t),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 34 * 8),
            child: Text(
              app.pickNote(),
              textAlign: TextAlign.center,
              style: Type.note(p.ink2),
            ),
          ),
        ),
      ],
    );
  }

  String _tally(AppState app, List<TaskItem> v) {
    final o = v.where((t) => !t.done).length;
    final dn = v.length - o;
    final n = app.sessionsToday();
    final parts = <String>[];
    if (o > 0) parts.add('$o to do');
    if (v.isNotEmpty && o == 0) parts.add('All done');
    if (dn > 0 && o > 0) parts.add('$dn done');
    if (n > 0) parts.add(n > 1 ? '$n focus sessions' : '$n focus session');
    if (app.d.h.isNotEmpty || app.d.bank > 0) {
      parts.add('momentum ${app.momentum().now}, bank ${app.d.bank.round()} min');
    }
    return parts.join(', ');
  }
}
