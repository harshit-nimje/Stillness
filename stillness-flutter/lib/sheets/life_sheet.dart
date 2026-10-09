import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/type.dart';
import '../models/stillness_data.dart';
import '../state/app_state.dart';
import '../theme/theme_scope.dart';
import '../widgets/controls.dart';
import '../widgets/icons.dart';
import '../widgets/sheet.dart';

/// The Momentum sheet — `#dLife`. Score + 14-day chart + time bank + Build and
/// Quit habit lists + the add-habit form.
class LifeSheet extends StatefulWidget {
  const LifeSheet({super.key});

  @override
  State<LifeSheet> createState() => _LifeSheetState();
}

class _LifeSheetState extends State<LifeSheet> {
  final _name = TextEditingController();
  String _kind = 'g';
  int _weight = 2;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final app = context.watch<AppState>();
    final m = app.momentum();

    return SheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Momentum', style: Type.h2(p.ink)),
          const SizedBox(height: 8),
          Text('Habits, focus and finished tasks build momentum and fill your time bank.',
              style: Type.body(p.ink2)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${m.now}', style: Type.mbig(p.ink)),
              const SizedBox(width: 14),
              AppChip(label: '${m.delta >= 0 ? '+' : ''}${m.delta} vs yesterday', selected: false),
            ],
          ),
          const SizedBox(height: 8),
          _Chart(series: m.series, color: p.ac),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time bank', style: Type.meta(p.ink2)),
                  Text('${app.d.bank.round()} min', style: Type.bankValue(p.ink)),
                ],
              ),
              AppButton(label: 'Spend 15', enabled: app.d.bank >= 15, onTap: app.spendBank),
            ],
          ),
          const SizedBox(height: 8),
          Text('Build', style: Type.body(p.ink2)),
          for (final h in app.d.h.where((x) => x.kind == 'g')) _habitRow(app, p, h),
          Text('Quit', style: Type.body(p.ink2)),
          for (final h in app.d.h.where((x) => x.kind == 'b')) _habitRow(app, p, h),
          const SizedBox(height: 14),
          // add-habit form
          Container(
            padding: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              border: Border.all(color: p.line, width: 1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    maxLength: 40,
                    style: Type.body(p.ink),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'New habit',
                      hintStyle: Type.body(p.ink2),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                _cycle(_kind == 'g' ? 'Build' : 'Quit', p, () => setState(() => _kind = _kind == 'g' ? 'b' : 'g')),
                const SizedBox(width: 4),
                _cycle(const ['Light', 'Medium', 'Heavy'][_weight - 1], p, () => setState(() => _weight = _weight % 3 + 1)),
                IconBtn(
                  body: Icons24.plus,
                  onTap: () {
                    app.addHabit(_name.text, _kind, _weight);
                    _name.clear();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            AppButton(label: 'Done', primary: true, onTap: () => Navigator.of(context).pop()),
          ]),
        ],
      ),
    );
  }

  /// A tap-to-cycle selector (stands in for the HTML `<select>`; no Material
  /// icon font is bundled, so we avoid DropdownButton).
  Widget _cycle(String label, dynamic p, VoidCallback onTap) => PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: p.hov, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: Type.body(p.ink)),
        ),
      );

  Widget _habitRow(AppState app, Palette p, Habit h) {
    final done = app.habitDoneToday(h.id);
    final build = h.kind == 'g';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => app.toggleHabit(h),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? p.ac : const Color(0x00000000),
                shape: BoxShape.circle,
                border: Border.all(color: done ? p.ac : p.ink2, width: 1.5),
              ),
              child: Center(
                child: done
                    ? svgStroke(Icons24.chk, color: const Color(0xFFFFFFFF), size: 16, strokeWidth: 2)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name, style: Type.taskText(p.ink)),
                Text(
                  build ? 'Tap when done, +${app.hw(h)}' : 'Tap if you slipped, ${app.hw(h)}',
                  style: Type.meta(p.ink2),
                ),
              ],
            ),
          ),
          IconBtn(body: Icons24.del, onTap: () => app.removeHabit(h)),
        ],
      ),
    );
  }
}

/// The 14-day momentum chart (`#mCh`, viewBox 0 0 280 70).
class _Chart extends StatelessWidget {
  const _Chart({required this.series, required this.color});
  final List<double> series;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mx = [20.0, ...series].reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < series.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == series.length - 1 ? 0 : 6),
                child: Container(
                  height: (series[i] / mx * 62).clamp(3, 62),
                  decoration: BoxDecoration(
                    color: color.withOpacity(i == series.length - 1 ? 1 : .35),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
