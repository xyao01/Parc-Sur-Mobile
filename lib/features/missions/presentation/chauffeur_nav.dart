import 'package:flutter/widgets.dart';

import '../../../core/widgets/parc_bottom_nav.dart';
import '../../../core/widgets/parc_icon.dart';

/// Chauffeur tab bar. Only « Missions » has a designed screen so far.
class ChauffeurBottomNav extends StatelessWidget {
  const ChauffeurBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return const ParcBottomNav(
      currentIndex: 0,
      items: [
        ParcNavItem(label: 'Missions', icon: ParcIcons.car),
        ParcNavItem(label: 'Planning', icon: ParcIcons.calendar),
        ParcNavItem(label: 'Alertes', icon: ParcIcons.bell),
        ParcNavItem(label: 'Profil', icon: ParcIcons.user),
      ],
    );
  }
}
