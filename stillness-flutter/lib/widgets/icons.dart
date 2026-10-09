import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The original ships its icons as inline SVG. We keep the exact vector
/// artwork and render it through flutter_svg, so nothing is approximated with
/// Material Icons.
class Icons24 {
  const Icons24._();

  // task row actions (IC)
  static const chk = '<path d="M6.5 12.5l3.5 3.5 7.5-8"/>';
  static const foc = '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="2.5"/>';
  static const up = '<path d="M12 19V6M6 11l6-6 6 6"/>';
  static const del = '<path d="M7 7l10 10M17 7L7 17"/>';
  static const ed = '<path d="M5 19l1-4L16 5l3 3L9 18z"/>';
  static const plus = '<path d="M12 5v14M5 12h14"/>';
  static const chevDown = '<path d="M6 9l6 6 6-6"/>';
  static const chevUp = '<path d="M6 15l6-6 6 6"/>';

  // dock
  static const sound =
      '<path d="M9 18V6l10-2v12"/><circle cx="6.5" cy="18" r="2.5"/><circle cx="16.5" cy="16" r="2.5"/>';
  static const focus = '<circle cx="12" cy="13" r="7.5"/><path d="M12 9v4l2.5 2M9.5 2.5h5"/>';
  static const breathe = '<circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="8"/>';
  static const life = '<path d="M4 17l5-5 4 3 7-8M15 7h5v5"/>';
  static const settings = '<path d="M4 8h16M4 16h16"/><circle cx="9" cy="8" r="2"/><circle cx="15" cy="16" r="2"/>';

  // onboarding marks (IK, viewBox 0 0 32 32)
  static const face = '<circle cx="16" cy="16" r="12"/><path d="M10 19q6 6 12 0M12 12.5v1M20 12.5v1"/>';
  static const sprout = '<path d="M16 28V14M16 18c-5 0-8-3-8-8 5 0 8 3 8 8M16 15c0-5 3-8 8-8 0 5-3 8-8 8"/>';
  static const quit = '<circle cx="16" cy="16" r="12"/><path d="M8 8l16 16"/>';
  static const task = '<circle cx="16" cy="16" r="12"/><path d="M10 16.5l4 4 8-9"/>';
  static const cloud = '<path d="M9 24a6 6 0 01-.5-12 8 8 0 0115.2 1.5A5 5 0 0123 24z"/>';
  static const file = '<path d="M8 3h12l5 5v21H8zM20 3v5h5M12 16h9M12 21h9"/>';
  static const dev = '<rect x="9" y="3" width="14" height="26" rx="3"/><path d="M14 25h4"/>';
}

String _hex(Color c) {
  // ignore: deprecated_member_use
  final v = c.value & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

/// Render an SVG body with an explicit stroke colour, matching the CSS
/// `fill:none; stroke:currentColor; stroke-linecap:round; stroke-linejoin:round`.
Widget svgStroke(
  String body, {
  required Color color,
  double size = 18,
  double strokeWidth = 1.6,
  String viewBox = '0 0 24 24',
}) {
  final svg = '<svg viewBox="$viewBox" fill="none" stroke="${_hex(color)}" '
      'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round">$body</svg>';
  return SvgPicture.string(svg, width: size, height: size);
}

/// A filled SVG body (e.g. the sea waves logo variant uses stroke too, but the
/// onboarding illustrations use fills).
Widget svgFill(String body, {required Color color, double size = 18, String viewBox = '0 0 24 24'}) {
  final svg = '<svg viewBox="$viewBox" fill="${_hex(color)}">$body</svg>';
  return SvgPicture.string(svg, width: size, height: size);
}
