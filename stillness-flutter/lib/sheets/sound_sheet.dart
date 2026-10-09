import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../audio/generated_scenes.dart';
import '../core/type.dart';
import '../state/audio.dart';
import '../theme/theme_scope.dart';
import '../widgets/controls.dart';
import '../widgets/icons.dart';
import '../widgets/sheet.dart';

/// The Soundscape sheet — `#dSound`. Two tabs: generated scenes with a custom
/// mix, and the curated library. Volume, the sleep timer and Silence/Done are
/// shared by both, exactly as in the original.
class SoundSheet extends StatefulWidget {
  const SoundSheet({super.key});

  @override
  State<SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<SoundSheet> {
  int _tab = 0; // 0 generated, 1 library
  bool _customOpen = false;

  @override
  void initState() {
    super.initState();
    _tab = context.read<AudioController>().libOn ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final audio = context.watch<AudioController>();

    return SheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Soundscape', style: Type.h2(p.ink)),
          const SizedBox(height: 8),
          Text('Shape a generated place, or pick a track from the library.', style: Type.body(p.ink2)),
          const SizedBox(height: 14),
          Row(
            children: [
              AppChip(label: 'Generated', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
              const SizedBox(width: 8),
              AppChip(label: 'Library', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
            ],
          ),
          const SizedBox(height: 14),
          if (_tab == 0) _generated(audio, p) else _library(audio, p),
          const SizedBox(height: 8),
          SliderRow(
            label: 'Volume',
            value: (audio.vol * 100).clamp(0, 100),
            min: 0,
            max: 100,
            onChanged: (v) => audio.setVolume(v / 100),
          ),
          const SizedBox(height: 8),
          Text('Fade out after', style: Type.body(p.ink2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in const [0, 15, 30, 60])
                AppChip(
                  label: m == 0 ? 'Off' : m == 60 ? '1 hour' : '$m min',
                  selected: audio.sm == m,
                  onTap: () => audio.setSleep(m),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AppButton(label: 'Silence', onTap: audio.silenceAll),
              const SizedBox(width: 10),
              AppButton(label: 'Done', primary: true, onTap: () => Navigator.of(context).pop()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _generated(AudioController audio, dynamic p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.1,
          children: [
            for (final s in kScenes.values)
              SceneButton(
                name: s.name,
                color: s.color,
                selected: audio.on && audio.key == s.key,
                onTap: () => audio.play(s.key),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _customOpen = !_customOpen),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text('Custom mix', style: Type.body(p.ink)),
                const SizedBox(width: 6),
                svgStroke(_customOpen ? Icons24.chevUp : Icons24.chevDown, color: p.ink2, size: 18, strokeWidth: 1.6),
              ],
            ),
          ),
        ),
        if (_customOpen)
          for (int i = 0; i < kLayers.length; i++)
            SliderRow(
              label: kLayers[i],
              value: (audio.mix[i] * 100).clamp(0, 100),
              min: 0,
              max: 100,
              onChanged: (v) => audio.setMixLayer(i, v / 100),
            ),
      ],
    );
  }

  Widget _library(AudioController audio, dynamic p) {
    final tracks = audio.tracks;
    final pos = audio.libDuration.inMilliseconds == 0
        ? 0.0
        : (audio.libPosition.inMilliseconds / audio.libDuration.inMilliseconds * 1000).clamp(0, 1000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in kCategories)
              AppChip(
                label: c,
                selected: audio.cat == c,
                onTap: () => audio.setCategory(c),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.line, width: 1),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: tracks.length,
              separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: p.line),
              itemBuilder: (context, i) {
                final t = tracks[i];
                final active = audio.curT == t;
                return PressScale(
                  onTap: () {
                    if (audio.curT != t) {
                      audio.playTrack(t);
                    } else if (audio.libPaused) {
                      audio.togglePlay();
                    } else {
                      audio.libPause();
                    }
                  },
                  child: Container(
                    color: active ? p.hov : const Color(0x00000000),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title, style: Type.trackTitle(p.ink)),
                              Text(t.artist, style: Type.trackArtist(p.ink2)),
                            ],
                          ),
                        ),
                        if (active) const _Equalizer(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Column(
            children: [
              Text(audio.curT?.title ?? 'Pick a track', style: Type.nowPlaying(p.ink)),
              const SizedBox(height: 4),
              if (audio.curT != null)
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse(audio.curT!.source)),
                  child: Text(
                    '${audio.curT!.artist}${audio.curT!.licence.isNotEmpty ? ' \u00b7 ${audio.curT!.licence}' : ''}',
                    textAlign: TextAlign.center,
                    style: Type.trackArtist(p.ink2),
                  ),
                ),
            ],
          ),
        ),
        Slider(
          value: pos,
          min: 0,
          max: 1000,
          onChangeStart: (_) => audio.seeking = true,
          onChanged: (v) => audio.seekFraction(v / 1000),
          onChangeEnd: (_) => audio.seeking = false,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppButton(label: '\u2039', onTap: () => audio.step(-1)),
            const SizedBox(width: 10),
            AppButton(label: audio.libPaused ? 'Play' : 'Pause', primary: true, onTap: audio.togglePlay),
            const SizedBox(width: 10),
            AppButton(label: '\u203a', onTap: () => audio.step(1)),
          ],
        ),
      ],
    );
  }
}

/// The little three-bar equaliser shown on the playing track.
class _Equalizer extends StatefulWidget {
  const _Equalizer();
  @override
  State<_Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<_Equalizer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    return SizedBox(
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Container(
                  width: 3,
                  height: 14 * (0.25 + 0.75 * ((_c.value + i * 0.25) % 1.0)),
                  decoration: BoxDecoration(color: p.ac, borderRadius: BorderRadius.circular(2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
