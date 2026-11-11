import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/missions/presentation/departure_check_screen.dart';
import '../features/missions/presentation/missions_screen.dart';
import '../features/requests/presentation/new_request_screen.dart';

const loginRoute = '/connexion';

GoRouter buildRouter(WidgetRef ref, {String initialLocation = loginRoute}) {
  return GoRouter(
    initialLocation: initialLocation,
    // Every screen except login requires a signed-in user.
    redirect: (_, state) {
      final signedIn = ref.read(sessionProvider) != null;
      if (!signedIn && state.matchedLocation != loginRoute) return loginRoute;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => loginRoute),
      GoRoute(path: loginRoute, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/missions',
        builder: (_, _) => const MissionsScreen(),
        routes: [
          GoRoute(
            path: ':id/controle-depart',
            builder: (_, state) => DepartureCheckScreen(missionId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/demandes/nouvelle', builder: (_, _) => const NewRequestScreen()),
    ],
  );
}
