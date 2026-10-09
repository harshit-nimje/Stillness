import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/tokens.dart';
import '../models/stillness_data.dart';
import '../sheets/day_sheet.dart';
import '../sheets/life_sheet.dart';
import '../sheets/settings_sheet.dart';
import '../sheets/sound_sheet.dart';
import '../screens/breathe_overlay.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding.dart';
import '../sky/sky.dart';
import '../sky/sky_view.dart';
import '../state/app_state.dart';
import '../state/audio.dart';
import '../state/breathe.dart';
import '../state/focus.dart';
import '../state/onboarding.dart';
import '../theme/theme_scope.dart';
import '../widgets/dock.dart';
import '../widgets/toast.dart';

/// The application shell: the sky behind, the scrolling content, the floating
/// dock, and the overlay stack (breathe, toast, onboarding). Owns the lifecycle
/// wiring (brightness, wake lock, back handling, first-run/day-rollover).
class StillnessApp extends StatefulWidget {
  const StillnessApp({super.key, required this.data});

  final StillnessData data;

  @override
  State<StillnessApp> createState() => _StillnessAppState();
}

class _StillnessAppState extends State<StillnessApp> with WidgetsBindingObserver {
  late final AppState _app = AppState(widget.data);
  late final SkyController _sky = SkyController();
  late final FocusController _focus = FocusController(_app);
  late final BreatheController _breathe = BreatheController();
  late final AudioController _audio = AudioController(_app);
  late final OnboardingController _ob = OnboardingController();

  bool _obVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _app.systemDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    _obVisible = !_app.d.ob;
    if (_obVisible) _ob.reset(rep: 0);

    _app.startClock();
    _audio.start();

    // wake lock during focus (screen stays on, like navigator.wakeLock)
    _focus.addListener(() {
      if (_focus.open) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    });

    // ring + chime + haptic on task completion
    _app.onTaskCompleted = (allDone, t) {
      HapticFeedback.vibrate();
      _sky.flashNow();
    };
    _app.onFocusTask = (t) => _focus.openStage(t.id);
    _app.onHabitDone = (h) {
      HapticFeedback.selectionClick();
      _sky.flashNow();
    };
    _app.onDayRollover = () {
      if (_obVisible) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSheet(context, (_) => const DaySheet());
      });
    };
    _focus.onPhaseEnd = (big) {
      HapticFeedback.vibrate();
      _sky.flashNow();
    };

    // first-run: nothing to do. returning user with a new day: open the ritual.
    if (_app.d.ob && _app.d.last != _app.today) {
      _app.d.tasks.removeWhere((t) => t.done);
      _app.save();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSheet(context, (_) => const DaySheet());
      });
    }
  }

  @override
  void didChangePlatformBrightness() {
    _app.systemDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _focus.dispose();
    _breathe.dispose();
    _audio.dispose();
    _app.dispose();
    _ob.dispose();
    _sky.dispose();
    super.dispose();
  }

  void _finishOnboarding(bool skip) {
    if (!skip) {
      _app.applyOnboarding(
        name: _ob.name,
        build: _ob.bs,
        quit: _ob.qs,
        firstTask: _ob.task,
      );
    }
    _app.d.ob = true;
    _app.d.last = _app.today;
    _app.save();
    _ob.hear = false;
    _audio.stop();
    setState(() => _obVisible = false);
    _app.say(_app.d.name.isNotEmpty ? 'Welcome, ${_app.d.name}.' : 'Welcome.');
  }

  void _replayIntro() {
    _ob.reset(rep: 1);
    setState(() => _obVisible = true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _app),
        ChangeNotifierProvider.value(value: _focus),
        ChangeNotifierProvider.value(value: _breathe),
        ChangeNotifierProvider.value(value: _audio),
        ChangeNotifierProvider.value(value: _ob),
        Provider.value(value: _sky),
      ],
      child: ThemeScope(
        palette: _sky.palette,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0x00000000),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          home: const _Shell(),
        ),
      ),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final app = context.watch<AppState>();
    final focus = context.watch<FocusController>();
    final breathe = context.watch<BreatheController>();
    final ob = context.watch<OnboardingController>();
    final state = context.findAncestorStateOfType<_StillnessAppState>()!;
    final obVisible = state._obVisible;

    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: !(focus.open || breathe.on || obVisible),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (obVisible) return;
        if (breathe.on) {
          breathe.setBreath(false);
        } else if (focus.open) {
          focus.closeStage();
        }
      },
      child: Scaffold(
        backgroundColor: p.bot,
        body: Stack(
          children: [
            // sky
            const Positioned.fill(child: SkyView()),
            // content
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 1000),
                opacity: (breathe.on || obVisible) ? 0 : 1,
                child: IgnorePointer(
                  ignoring: breathe.on || obVisible,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      topPad + (MediaQuery.sizeOf(context).height * .10).clamp(36.0, 96.0),
                      22,
                      Tokens.mainBottomPad,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: Tokens.maxWidth),
                        child: const HomeScreen(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // dock
            Positioned(
              left: 0,
              right: 0,
              bottom: Tokens.dockBottomInset + bottomPad,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: obVisible ? 0 : 1,
                child: IgnorePointer(
                  ignoring: obVisible,
                  child: Center(
                    child: Dock(
                      onSound: () => showSheet(context, (_) => const SoundSheet()),
                      onLife: () => showSheet(context, (_) => const LifeSheet()),
                      onSettings: () => showSheet(
                        context,
                        (ctx) => SettingsSheet(onReplayIntro: () {
                          Navigator.of(ctx).pop();
                          state._replayIntro();
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // breathe overlay
            if (breathe.on) const Positioned.fill(child: BreatheOverlay()),
            // onboarding
            if (obVisible)
              OnboardingOverlay(
                onClose: () => state._finishOnboarding(true),
                onFinish: (skip) => state._finishOnboarding(skip),
              ),
            // toast on top
            const ToastLayer(),
          ],
        ),
      ),
    );
  }
}
