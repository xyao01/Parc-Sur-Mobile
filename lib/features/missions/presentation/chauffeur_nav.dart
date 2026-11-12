import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/parc_bottom_nav.dart';
import '../../../core/widgets/parc_icon.dart';

/// Chauffeur tab bar: Missions (C01), Planning (C11), Alertes (C12), Profil.
class ChauffeurBottomNav extends StatelessWidget {
  const ChauffeurBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return ParcBottomNav(
      currentIndex: currentIndex,
      items: [
        ParcNavItem(label: 'Missions', icon: ParcIcons.car, onTap: () => context.go(Routes.missions)),
        ParcNavItem(label: 'Planning', icon: ParcIcons.calendar, onTap: () => context.go(Routes.planning)),
        ParcNavItem(label: 'Alertes', icon: ParcIcons.bell, onTap: () => context.go(Routes.alerts)),
        ParcNavItem(label: 'Profil', icon: ParcIcons.user, onTap: () => context.go(Routes.profile)),
      ],
    );
  }
}
