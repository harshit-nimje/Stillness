import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/type.dart';
import '../models/stillness_data.dart';
import '../state/app_state.dart';
import '../theme/theme_scope.dart';
import '../widgets/controls.dart';
import '../widgets/sheet.dart';
import '../widgets/task_row.dart';

/// The morning ritual — `#dDay`. Once a day, skippable. Carry-over is "let go",
/// not "tick what you finished".
class DaySheet extends StatefulWidget {
  const DaySheet({super.key});

  @override
  State<DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<DaySheet> {
  final _name = TextEditingController();
  final _task = TextEditingController();
  final _good = TextEditingController();
  final Set<String> _drop = {};
  final List<String> _staged = [];

  @override
  void initState() {
    super.initState();
    _name.text = context.read<AppState>().d.name;
  }

  @override
  void dispose() {
    _name.dispose();
    _task.dispose();
    _good.dispose();
    super.dispose();
  }

  void _stage() {
    final v = _task.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _staged.add(v);
      _task.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final app = context.watch<AppState>();
    final old = app.visibleTasks().where((t) => !t.done).toList();

    return SheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.dateLine(), style: Type.body(p.ink2)),
          const SizedBox(height: 4),
          Text(app.greeting(), style: Type.h2(p.ink)),
          if (app.d.name.isEmpty) ...[
            const SizedBox(height: 14),
            Text('What should I call you?', style: Type.body(p.ink2)),
            const SizedBox(height: 6),
            TextField(controller: _name, maxLength: 40, style: Type.body(p.ink), decoration: _field(p)),
          ],
          if (old.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Carried over. Let go of anything that no longer matters.', style: Type.body(p.ink2)),
            const SizedBox(height: 8),
            for (final t in old.take(6))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: StrikeText(
                        text: t.title,
                        style: Type.taskText(p.ink),
                        struck: _drop.contains(t.id),
                        lineColor: p.ink,
                      ),
                    ),
                    AppChip(
                      label: 'Let go',
                      selected: _drop.contains(t.id),
                      onTap: () => setState(() {
                        if (_drop.contains(t.id)) {
                          _drop.remove(t.id);
                        } else {
                          _drop.add(t.id);
                        }
                      }),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 18),
          Text('What would make today good?', style: Type.body(p.ink2)),
          const SizedBox(height: 6),
          TextField(
            controller: _task,
            maxLength: 120,
            style: Type.body(p.ink),
            decoration: _field(p, hint: 'Type a task and press Enter'),
            onSubmitted: (_) => _stage(),
          ),
          if (_staged.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final s in _staged) AppChip(label: s, selected: false)],
              ),
            ),
          const SizedBox(height: 14),
          Text('One small good thing from yesterday', style: Type.body(p.ink2)),
          const SizedBox(height: 6),
          TextField(controller: _good, maxLength: 140, style: Type.body(p.ink), decoration: _field(p)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            children: [
              AppButton(
                label: 'Begin the day',
                primary: true,
                onTap: () {
                  _stage();
                  app.beginDay(
                    name: _name.text,
                    dropIds: _drop.toList(),
                    newTasks: List.of(_staged),
                    goodThing: _good.text,
                  );
                  Navigator.of(context).pop();
                },
              ),
              AppButton(
                label: 'Not now',
                onTap: () {
                  app.markLast();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _field(dynamic p, {String? hint}) => InputDecoration(
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: p.hov,
        hintText: hint,
        hintStyle: Type.body(p.ink2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.ac, width: 1),
        ),
      );
}
