import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_role.dart';
import '../features/auth/application/session.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/new_password_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/missions/presentation/arrival_screen.dart';
import '../features/missions/presentation/closure_screen.dart';
import '../features/missions/presentation/departure_preparation_screen.dart';
import '../features/missions/presentation/departure_validation_screen.dart';
import '../features/missions/presentation/driver_home_screen.dart';
import '../features/missions/presentation/end_check_screen.dart';
import '../features/missions/presentation/mission_details_screen.dart';
import '../features/missions/presentation/mission_in_progress_screen.dart';
import '../features/missions/presentation/new_request_notice_screen.dart';
import '../features/missions/presentation/planning_screen.dart';
import '../features/missions/presentation/request_response_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/requests/presentation/new_request_screen.dart';
import 'routes.dart';

const loginRoute = Routes.login;

/// Access rules:
/// - signed out → only sign-in, « mot de passe oublié » and the reset page;
/// - provisional password → only the new password screen;
/// - otherwise the new password screen is closed.
String? accessRedirect(WidgetRef ref, String location) {
  final profile = ref.read(sessionProvider);
  if (profile == null) return Routes.public.contains(location) ? null : Routes.login;
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
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: Routes.resetPassword, builder: (_, _) => const ResetPasswordScreen()),
      // Driver journey Mob-C01…C10.
      GoRoute(
        path: Routes.missions,
        builder: (_, _) => const DriverHomeScreen(),
        routes: [
          GoRoute(path: 'demandes/:id', builder: (_, s) => NewRequestNoticeScreen(missionId: s.pathParameters['id']!)),
          GoRoute(path: 'demandes/:id/details', builder: (_, s) => MissionDetailsScreen(missionId: s.pathParameters['id']!)),
          GoRoute(
            path: 'demandes/:id/reponse',
            builder: (_, s) => RequestResponseScreen(
              missionId: s.pathParameters['id']!,
              accept: s.uri.queryParameters['choix'] != 'refuser',
            ),
          ),
          GoRoute(path: ':id/preparation', builder: (_, s) => DeparturePreparationScreen(missionId: s.pathParameters['id']!)),
          GoRoute(path: ':id/validation', builder: (_, s) => DepartureValidationScreen(missionId: s.pathParameters['id']!)),
          GoRoute(path: ':id/en-cours', builder: (_, s) => MissionInProgressScreen(missionId: s.pathParameters['id']!)),
          GoRoute(path: ':id/arrivee', builder: (_, s) => ArrivalScreen(missionId: s.pathParameters['id']!)),
          GoRoute(path: ':id/controle-fin', builder: (_, s) => EndCheckScreen(missionId: s.pathParameters['id']!)),
          GoRoute(path: ':id/cloture', builder: (_, s) => ClosureScreen(missionId: s.pathParameters['id']!)),
        ],
      ),
      GoRoute(path: Routes.planning, builder: (_, _) => const PlanningScreen()),
      GoRoute(path: Routes.newRequest, builder: (_, _) => const NewRequestScreen()),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
    ],
  );
}
