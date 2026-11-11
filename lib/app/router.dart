import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/missions/presentation/departure_check_screen.dart';
import '../features/missions/presentation/missions_screen.dart';
import '../features/requests/presentation/new_request_screen.dart';

GoRouter buildRouter({String initialLocation = '/connexion'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/connexion'),
      GoRoute(path: '/connexion', builder: (_, _) => const LoginScreen()),
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
