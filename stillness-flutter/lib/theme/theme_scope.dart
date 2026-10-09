import 'package:flutter/widgets.dart';

import '../core/tokens.dart';

/// Exposes the live [Palette] (sky colours + theme) to the widget tree. It is
/// an [InheritedNotifier] over the sky controller's palette notifier, which
/// only fires on a ~500ms throttle — so the tree re-themes a couple of times a
/// second at most, never per frame.
class ThemeScope extends InheritedNotifier<ValueNotifier<Palette>> {
  const ThemeScope({super.key, required ValueNotifier<Palette> palette, required super.child})
      : super(notifier: palette);

  static Palette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!.value;
}
