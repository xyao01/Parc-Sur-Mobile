import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stroke icons copied path-for-path from the prototype (24×24 viewBox).
/// `currentColor` is resolved through [ParcIcon.color].
abstract final class ParcIcons {
  static const _o = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round"';

  static const eye = '$_o stroke-width="2"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>';
  static const fingerprint = '$_o stroke-width="2"><path d="M12 11v4M8 12a4 4 0 0 1 8 0v3M5 11a7 7 0 0 1 14 0v2M9 19c.6-1 1-2.4 1-4M15 19c-.4-1-.6-2-.6-3"/></svg>';
  static const back = '$_o stroke-width="2.5"><path d="M15 6l-6 6 6 6"/></svg>';
  static const chevronRight = '$_o stroke-width="2.5"><path d="M9 6l6 6-6 6"/></svg>';
  static const arrowRight = '$_o stroke-width="2.5"><path d="M5 12h14M13 6l6 6-6 6"/></svg>';
  static const fuel = '$_o stroke-width="2" stroke-linejoin="round"><path d="M4 21V5a2 2 0 0 1 2-2h7a2 2 0 0 1 2 2v16M3 21h13M4 10h11M15 8l3 3v6a2 2 0 0 0 4 0V9l-3-3"/></svg>';
  static const warning = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M12 3l10 18H2z"/><path d="M12 10v5M12 18v.5"/></svg>';
  static const car = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M3 13l2-6h14l2 6v5H3z"/><circle cx="7.5" cy="18" r="1.5"/><circle cx="16.5" cy="18" r="1.5"/></svg>';
  static const calendar = '$_o stroke-width="2"><rect x="3" y="4" width="18" height="17" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></svg>';
  static const bell = '$_o stroke-width="2"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10 21a2 2 0 0 0 4 0"/></svg>';
  static const user = '$_o stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/></svg>';
  static const home = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/></svg>';
  static const checkSquare = '$_o stroke-width="2" stroke-linejoin="round"><path d="M9 11l3 3 8-8"/><path d="M20 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>';
  static const info = '$_o stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8v.5"/></svg>';
  static const wifiOff = '$_o stroke-width="2"><path d="M2 8.5a15 15 0 0 1 20 0M5 12a10 10 0 0 1 14 0M8.5 15.5a5 5 0 0 1 7 0M12 19h.01"/><path d="M3 3l18 18"/></svg>';
  static const plus = '$_o stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>';
  static const check = '$_o stroke-width="3.5" stroke-linejoin="round"><path d="M5 12l5 5 9-10"/></svg>';
  static const close = '$_o stroke-width="2.5"><path d="M18 6L6 18M6 6l12 12"/></svg>';
  static const phone = '$_o stroke-width="2" stroke-linejoin="round"><path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/></svg>';
  static const clock = '$_o stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>';
  static const mapPin = '$_o stroke-width="2.5" stroke-linejoin="round"><path d="M12 21s-7-6.5-7-12a7 7 0 0 1 14 0c0 5.5-7 12-7 12z"/><circle cx="12" cy="9" r="2.5"/></svg>';
  static const blocked = '$_o stroke-width="2.5"><circle cx="12" cy="12" r="9"/><path d="M5.6 5.6l12.8 12.8"/></svg>';
  static const cross = '$_o stroke-width="3"><path d="M6 6l12 12M18 6L6 18"/></svg>';
  static const checkBold = '$_o stroke-width="3" stroke-linejoin="round"><path d="M5 12l5 5 9-10"/></svg>';
}

class ParcIcon extends StatelessWidget {
  const ParcIcon(this.svg, {super.key, this.size = 22, required this.color});

  final String svg;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.string(
        svg,
        width: size,
        height: size,
        theme: SvgTheme(currentColor: color),
      ),
    );
  }
}
