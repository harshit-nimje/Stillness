import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/type.dart';
import '../sky/sky_painter.dart';
import '../state/breathe.dart';
import '../theme/theme_scope.dart';
import '../widgets/controls.dart';

/// The breathing overlay — `#bw`. The circle itself is painted by the sky; this
/// layer holds the phase label, the countdown, the pattern chips and Done.
class BreatheOverlay extends StatelessWidget {
  const BreatheOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final breathe = context.watch<BreatheController>();
    final h = MediaQuery.sizeOf(context).height;

    return Stack(
      children: [
        Positioned(
          top: h * .42,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Transform.translate(
                offset: const Offset(0, -1.3 * 35),
                child: Text(breathe.label, style: Type.breathLabel(p.ink)),
              ),
              Transform.translate(
                offset: const Offset(0, .5 * 17),
                child: Text('${breathe.count}', style: Type.breathCount(p.ink2)),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 100 + MediaQuery.paddingOf(context).bottom,
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final entry in kBreathPatterns.entries)
                    AppChip(
                      label: entry.value.name,
                      selected: breathe.kind == entry.key,
                      onTap: () => breathe.setBreath(true, k: entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AppButton(label: 'Done', onTap: () => breathe.setBreath(false)),
            ],
          ),
        ),
      ],
    );
  }
}
