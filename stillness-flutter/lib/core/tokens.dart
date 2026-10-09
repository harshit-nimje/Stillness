import 'package:flutter/widgets.dart';

/// Design tokens translated 1:1 from the Stillness CSS `:root` custom
/// properties. The sky colours (top/bot/ac) are NOT here — they are written
/// every frame by the sky controller from the real clock, exactly like the
/// original writes `--top`, `--bot`, `--ac` onto `document.documentElement`.
class Tokens {
  const Tokens._();

  // ---- Typography families (bundled locally; no Google Fonts at runtime) ----
  static const String serif = 'Newsreader';
  static const String sans = 'Hanken Grotesk';

  // ---- Light palette (defaults before the clock paints them) ----
  static const Color lightInk = Color(0xFF23213F);
  static const Color lightInk2 = Color(0xB823213F); // rgba(35,33,63,.72)
  static const Color lightLine = Color(0x2123213F); // rgba(35,33,63,.13)
  static const Color lightGlass = Color(0x80FFFFFF); // rgba(255,255,255,.5)
  static const Color lightSheet = Color(0xCCFFFFFF); // rgba(255,255,255,.8)
  static const Color lightEdge = Color(0xCCFFFFFF); // rgba(255,255,255,.8)
  static const Color lightShade = Color(0x4D322C6E); // rgba(50,44,110,.3)
  static const Color lightHov = Color(0x1223213F); // rgba(35,33,63,.07)

  // ---- Dark palette ----
  static const Color darkInk = Color(0xFFECE9FB);
  static const Color darkInk2 = Color(0xBDECE9FB); // rgba(236,233,251,.74)
  static const Color darkLine = Color(0x24ECE9FB); // rgba(236,233,251,.14)
  static const Color darkGlass = Color(0x12FFFFFF); // rgba(255,255,255,.07)
  static const Color darkSheet = Color(0xD616142E); // rgba(22,20,46,.84)
  static const Color darkEdge = Color(0x24FFFFFF); // rgba(255,255,255,.14)
  static const Color darkShade = Color(0xB3000000); // rgba(0,0,0,.7)
  static const Color darkHov = Color(0x1AFFFFFF); // rgba(255,255,255,.1)

  // ---- Radii ----
  static const double rPanel = 26;
  static const double rSheet = 30;
  static const double rScene = 18;
  static const double rPill = 999;
  static const double rField = 16;
  static const double rOpt = 20;

  // ---- Layout ----
  static const double maxWidth = 560;
  static const double dockBottomInset = 14;
  static const double mainBottomPad = 160;

  // ---- Motion ----
  static const Duration tFast = Duration(milliseconds: 200);
  static const Duration tSheet = Duration(milliseconds: 400);
  static const Duration tSheetOut = Duration(milliseconds: 220);
  static const Duration tRise = Duration(milliseconds: 500);

  /// The single shared easing curve: cubic-bezier(.2,.7,.2,1).
  static const Curve ease = Cubic(0.2, 0.7, 0.2, 1);

  /// cubic-bezier(.6,0,.2,1) — the strike-through grow.
  static const Curve easeStrike = Cubic(0.6, 0.0, 0.2, 1);

  /// cubic-bezier(.2,.9,.3,1.5) — the checkbox pop.
  static const Curve easePop = Cubic(0.2, 0.9, 0.3, 1.5);

  // ---- Glass blur ----
  static const double glassBlur = 22;
  static const double glassSaturate = 1.4;
}

/// The resolved colour set for the current theme + sky. Equivalent to the CSS
/// custom properties after JS has written `--top/--bot/--ac` and the
/// `data-theme` attribute has selected the light/dark block.
@immutable
class Palette {
  final Color top;
  final Color bot;
  final Color ac;
  final Color ink;
  final Color ink2;
  final Color line;
  final Color glass;
  final Color sheet;
  final Color edge;
  final Color shade;
  final Color hov;
  final bool isDark;

  const Palette({
    required this.top,
    required this.bot,
    required this.ac,
    required this.ink,
    required this.ink2,
    required this.line,
    required this.glass,
    required this.sheet,
    required this.edge,
    required this.shade,
    required this.hov,
    required this.isDark,
  });

  /// Build the ink/line/glass half of the palette from the dark flag.
  factory Palette.forTheme({
    required Color top,
    required Color bot,
    required Color ac,
    required bool isDark,
  }) {
    return Palette(
      top: top,
      bot: bot,
      ac: ac,
      ink: isDark ? Tokens.darkInk : Tokens.lightInk,
      ink2: isDark ? Tokens.darkInk2 : Tokens.lightInk2,
      line: isDark ? Tokens.darkLine : Tokens.lightLine,
      glass: isDark ? Tokens.darkGlass : Tokens.lightGlass,
      sheet: isDark ? Tokens.darkSheet : Tokens.lightSheet,
      edge: isDark ? Tokens.darkEdge : Tokens.lightEdge,
      shade: isDark ? Tokens.darkShade : Tokens.lightShade,
      hov: isDark ? Tokens.darkHov : Tokens.lightHov,
      isDark: isDark,
    );
  }

  /// `:root[data-sc]` overrides edge + shade to derive from the accent colour
  /// while a generated scene is playing.
  Palette withScene() {
    return Palette(
      top: top,
      bot: bot,
      ac: ac,
      ink: ink,
      ink2: ink2,
      line: line,
      glass: glass,
      sheet: sheet,
      edge: Color.alphaBlend(ac.withOpacity(0.38), const Color(0x00000000)),
      shade: Color.alphaBlend(ac.withOpacity(0.50), const Color(0x59000000)),
      hov: hov,
      isDark: isDark,
    );
  }

  Palette copyWith({Color? top, Color? bot, Color? ac}) => Palette(
        top: top ?? this.top,
        bot: bot ?? this.bot,
        ac: ac ?? this.ac,
        ink: ink,
        ink2: ink2,
        line: line,
        glass: glass,
        sheet: sheet,
        edge: edge,
        shade: shade,
        hov: hov,
        isDark: isDark,
      );
}

/// Component-wise mix — the JS `mixC(a, b, f)`. Uses [Color.lerp] so it works
/// across Flutter versions without touching deprecated channel accessors.
Color mixColor(Color a, Color b, double f) => Color.lerp(a, b, f)!;
