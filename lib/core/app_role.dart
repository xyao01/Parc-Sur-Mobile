import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mobile profiles covered by the prototype.
enum AppRole { chauffeur, demandeur }

/// Role of the signed-in user.
///
/// Configurable parameter until authentication is wired: set with
/// `--dart-define=PARCSUR_ROLE=demandeur` (default `chauffeur`).
final currentRoleProvider = Provider<AppRole>((ref) {
  const raw = String.fromEnvironment('PARCSUR_ROLE', defaultValue: 'chauffeur');
  return AppRole.values.firstWhere((r) => r.name == raw, orElse: () => AppRole.chauffeur);
});

/// Home route for a role.
String homeRouteFor(AppRole role) => switch (role) {
      AppRole.chauffeur => '/missions',
      AppRole.demandeur => '/demandes/nouvelle',
    };
