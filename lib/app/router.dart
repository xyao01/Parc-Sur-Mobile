import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_role.dart';
import '../features/auth/application/session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/new_password_screen.dart';
import '../features/missions/presentation/departure_check_screen.dart';
import '../features/missions/presentation/missions_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/requests/presentation/new_request_screen.dart';
import 'routes.dart';

const loginRoute = Routes.login;

/// Access rules:
/// - signed out → only the login screen;
/// - provisional password → only the new password screen;
/// - otherwise the new password screen is closed.
String? accessRedirect(WidgetRef ref, String location) {
  final profile = ref.read(sessionProvider);
  if (profile == null) return location == Routes.login ? null : Routes.login;
  if (profile.mustChangePassword) return location == Routes.newPassword ? null : Routes.newPassword;
  if (location == Routes.newPassword) return homeRouteFor(profile.roles);
  return null;
}

GoRouter buildRouter(WidgetRef ref, {String initialLocation = Routes.login}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (_, state) => accessRedirect(ref, state.matchedLocation),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.login),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.newPassword, builder: (_, _) => const NewPasswordScreen()),
      GoRoute(
        path: Routes.missions,
        builder: (_, _) => const MissionsScreen(),
        routes: [
          GoRoute(
            path: ':id/controle-depart',
            builder: (_, state) => DepartureCheckScreen(missionId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: Routes.newRequest, builder: (_, _) => const NewRequestScreen()),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
    ],
  );
}
