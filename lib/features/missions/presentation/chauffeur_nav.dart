import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/parc_bottom_nav.dart';
import '../../../core/widgets/parc_icon.dart';

/// Chauffeur tab bar. Planning is not designed yet; Alertes opens the new request (Mob-C01).
class ChauffeurBottomNav extends StatelessWidget {
  const ChauffeurBottomNav({super.key, required this.currentIndex, this.onAlerts});

  final int currentIndex;
  final VoidCallback? onAlerts;

  @override
  Widget build(BuildContext context) {
    return ParcBottomNav(
      currentIndex: currentIndex,
      items: [
        ParcNavItem(label: 'Missions', icon: ParcIcons.car, onTap: () => context.go(Routes.missions)),
        ParcNavItem(label: 'Planning', icon: ParcIcons.calendar, onTap: () => context.go(Routes.planning)),
        ParcNavItem(label: 'Alertes', icon: ParcIcons.bell, onTap: onAlerts),
        ParcNavItem(label: 'Profil', icon: ParcIcons.user, onTap: () => context.go(Routes.profile)),
      ],
    );
  }
}
