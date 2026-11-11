import 'package:flutter/widgets.dart';

import '../../../core/widgets/parc_bottom_nav.dart';
import '../../../core/widgets/parc_icon.dart';

/// Demandeur tab bar. « Mes demandes » is the active tab on the new request form.
class DemandeurBottomNav extends StatelessWidget {
  const DemandeurBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return const ParcBottomNav(
      currentIndex: 1,
      items: [
        ParcNavItem(label: 'Accueil', icon: ParcIcons.home),
        ParcNavItem(label: 'Mes demandes', icon: ParcIcons.checkSquare),
        ParcNavItem(label: 'Alertes', icon: ParcIcons.bell),
        ParcNavItem(label: 'Profil', icon: ParcIcons.user),
      ],
    );
  }
}
