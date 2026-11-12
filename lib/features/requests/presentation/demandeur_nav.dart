import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/parc_bottom_nav.dart';
import '../../../core/widgets/parc_icon.dart';

/// Demandeur tab bar: Accueil (D01), Mes demandes (D05), Alertes (C12), Profil.
class DemandeurBottomNav extends StatelessWidget {
  const DemandeurBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return ParcBottomNav(
      currentIndex: currentIndex,
      items: [
        ParcNavItem(label: 'Accueil', icon: ParcIcons.home, onTap: () => context.go(Routes.requesterHome)),
        ParcNavItem(label: 'Mes demandes', icon: ParcIcons.checkSquare, onTap: () => context.go(Routes.myRequests)),
        ParcNavItem(label: 'Alertes', icon: ParcIcons.bell, onTap: () => context.go(Routes.alerts)),
        ParcNavItem(label: 'Profil', icon: ParcIcons.user, onTap: () => context.go(Routes.profile)),
      ],
    );
  }
}
