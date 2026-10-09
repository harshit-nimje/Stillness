import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/type.dart';
import '../state/app_state.dart';
import '../state/focus.dart';
import '../theme/theme_scope.dart';
import '../widgets/controls.dart';
import '../widgets/icons.dart';
import '../widgets/sheet.dart';

/// The Settings sheet — `#dMore`. Focus/rest config, name, appearance,
/// account, and backup/restore.
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, this.onReplayIntro});

  final VoidCallback? onReplayIntro;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final _name = TextEditingController();
  final _backup = TextEditingController();
  bool _backupOpen = false;

  @override
  void initState() {
    super.initState();
    _name.text = context.read<AppState>().d.name;
  }

  @override
  void dispose() {
    _name.dispose();
    _backup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final app = context.watch<AppState>();

    return SheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Type.h2(p.ink)),
          const SizedBox(height: 8),
          Text(app.statsLine(), style: Type.body(p.ink2)),
          const SizedBox(height: 8),
          SliderRow(
            label: 'Focus',
            value: app.d.cfg.focus,
            min: 5,
            max: 60,
            divisions: 11,
            trailing: Text('${app.d.cfg.focus.round()} min', style: Type.meta(p.ink2)),
            onChanged: (v) {
              app.setConfig(focus: (v / 5).round() * 5.0);
              context.read<FocusController>().syncFromConfig();
            },
          ),
          SliderRow(
            label: 'Rest',
            value: app.d.cfg.rest,
            min: 1,
            max: 30,
            divisions: 29,
            trailing: Text('${app.d.cfg.rest.round()} min', style: Type.meta(p.ink2)),
            onChanged: (v) => app.setConfig(rest: v.roundToDouble()),
          ),
          SliderRow(
            label: 'Long rest',
            value: app.d.cfg.longRest,
            min: 10,
            max: 45,
            divisions: 7,
            trailing: Text('${app.d.cfg.longRest.round()} min', style: Type.meta(p.ink2)),
            onChanged: (v) => app.setConfig(longRest: (v / 5).round() * 5.0),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => app.setConfig(auto: !app.d.cfg.auto),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: app.d.cfg.auto,
                    activeColor: p.ac,
                    side: BorderSide(color: p.line, width: 1.5),
                    onChanged: (v) => app.setConfig(auto: v ?? false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text('Start the next session automatically', style: Type.body(p.ink))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _label('Name'),
          TextField(
            controller: _name,
            maxLength: 40,
            style: Type.body(p.ink),
            decoration: _field(p),
            onChanged: app.setName,
          ),
          const SizedBox(height: 6),
          Text('Account', style: Type.body(p.ink2)),
          const SizedBox(height: 4),
          Text(
            'Local only. Your data is saved on this device. Use Backup below to move it.',
            style: Type.meta(p.ink2),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              AppButton(
                label: 'Sync now',
                onTap: () => app.say('Cloud sync is not available in this build.'),
              ),
              AppButton(label: 'Replay intro', onTap: widget.onReplayIntro),
            ],
          ),
          const SizedBox(height: 14),
          Text('Appearance', style: Type.body(p.ink2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in const [['auto', 'Auto'], ['light', 'Light'], ['dark', 'Dark']])
                AppChip(
                  label: entry[1],
                  selected: app.d.theme == entry[0],
                  onTap: () => app.setTheme(entry[0]),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() => _backupOpen = !_backupOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text('Back up or move your data', style: Type.body(p.ink)),
                  const SizedBox(width: 6),
                  svgStroke(_backupOpen ? Icons24.chevUp : Icons24.chevDown, color: p.ink2, size: 18, strokeWidth: 1.6),
                ],
              ),
            ),
          ),
          if (_backupOpen) ...[
            Text(
              'Copy this text to keep a backup. To restore on another device, paste it here and choose Restore.',
              style: Type.body(p.ink2),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _backup,
              maxLines: 4,
              style: Type.sans(size: 12, color: p.ink).copyWith(fontFamily: 'monospace'),
              decoration: _field(p),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                AppButton(
                  label: 'Copy backup',
                  onTap: () async {
                    final text = app.backupText();
                    _backup.text = text;
                    await Clipboard.setData(ClipboardData(text: text));
                    app.say('Backup copied.');
                  },
                ),
                AppButton(
                  label: 'Restore',
                  onTap: () {
                    final ok = app.restore(_backup.text);
                    if (ok) _backup.clear();
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Shortcuts: n adds a task. Alt with the up and down arrows reorders. Esc leaves focus or breathing.',
            style: Type.body(p.ink2),
          ),
          const SizedBox(height: 16),
          Row(children: [
            AppButton(label: 'Done', primary: true, onTap: () => Navigator.of(context).pop()),
          ]),
        ],
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s, style: Type.body(ThemeScope.of(context).ink2)),
      );

  InputDecoration _field(dynamic p) => InputDecoration(
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: p.hov,
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
