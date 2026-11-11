import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/parc_bottom_nav.dart';
import '../../../core/widgets/parc_icon.dart';

/// Demandeur tab bar. Accueil and Alertes are not designed yet.
class DemandeurBottomNav extends StatelessWidget {
  const DemandeurBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return ParcBottomNav(
      currentIndex: currentIndex,
      items: [
        const ParcNavItem(label: 'Accueil', icon: ParcIcons.home),
        ParcNavItem(label: 'Mes demandes', icon: ParcIcons.checkSquare, onTap: () => context.go(Routes.newRequest)),
        const ParcNavItem(label: 'Alertes', icon: ParcIcons.bell),
        ParcNavItem(label: 'Profil', icon: ParcIcons.user, onTap: () => context.go(Routes.profile)),
      ],
    );
  }
}
