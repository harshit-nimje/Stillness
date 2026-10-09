import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/type.dart';
import '../state/app_state.dart';
import '../state/focus.dart';
import '../theme/theme_scope.dart';
import '../widgets/controls.dart';

/// The focus stage — `#stage`. Big serif task line, the ringed countdown, the
/// mode label, and the Resume/Pause · Done · End row.
class FocusStage extends StatelessWidget {
  const FocusStage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final focus = context.watch<FocusController>();
    final app = context.read<AppState>();

    final t = app.byId(focus.taskId);
    final modeName = {'f': 'Focus', 'b': 'Rest', 'l': 'Long rest'}[focus.mode] ?? 'Focus';
    final taskLabel = t != null
        ? t.title
        : focus.mode == 'f'
            ? 'A quiet stretch of focus'
            : 'Look away from the screen';

    final len = focus.len(focus.mode);
    final progress = len == 0 ? 0.0 : (1 - focus.left / len).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 20 * 12),
            child: Text(
              taskLabel,
              textAlign: TextAlign.center,
              style: Type.stageTask(context, p.ink),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: FocusDial(
              progress: progress,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(FocusController.fmt(focus.left), style: Type.stageTime(context, p.ink)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$modeName${focus.run ? '' : ', paused'}',
            style: Type.body(p.ink2),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              AppButton(label: focus.run ? 'Pause' : 'Resume', primary: true, onTap: focus.toggleRun),
              if (t != null && !t.done && focus.mode == 'f')
                AppButton(
                  label: 'Done',
                  onTap: () {
                    app.complete(t);
                    focus.endSession();
                  },
                ),
              AppButton(label: 'End', onTap: focus.endSession),
            ],
          ),
        ],
      ),
    );
  }
}
