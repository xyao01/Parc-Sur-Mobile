import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_role.dart';
import '../../auth/application/session.dart';
import 'profile_gateway.dart';
import 'supabase_profile_gateway.dart';

final profileGatewayProvider = Provider<ProfileGateway>((ref) => SupabaseProfileGateway(Supabase.instance.client));

/// « Mes informations » of a requester (own `utilisateur` row); `null` without web record.
class AccountDetails {
  const AccountDetails({this.phone, this.location, this.function});

  factory AccountDetails.fromJson(Map<String, dynamic> j) {
    String? text(String k) {
      final s = (j[k] as String?)?.trim();
      return s == null || s.isEmpty ? null : s;
    }

    return AccountDetails(phone: text('phone'), location: text('localisation'), function: text('fonction'));
  }

  final String? phone;
  final String? location;
  final String? function;
}

final accountDetailsProvider = FutureProvider.autoDispose<AccountDetails?>((ref) async {
  final profile = ref.watch(sessionProvider);
  if (profile == null || !profile.roles.contains(AppRole.demandeur)) return null;
  final row = await ref.watch(profileGatewayProvider).myAccount(profile.email);
  return row == null ? null : AccountDetails.fromJson(row);
});

/// Space shown to a user who is both driver and requester (Mob-P01 « Mon espace »).
/// Starts on `AuthConfig.preferredRole`; a single-role user always has their role.
final activeSpaceProvider = NotifierProvider<ActiveSpaceNotifier, AppRole?>(ActiveSpaceNotifier.new);

class ActiveSpaceNotifier extends Notifier<AppRole?> {
  @override
  AppRole? build() {
    final roles = ref.watch(sessionProvider)?.roles ?? const <AppRole>{};
    if (roles.isEmpty) return null;
    return roles.contains(AuthConfig.preferredRole) ? AuthConfig.preferredRole : roles.first;
  }

  void select(AppRole role) {
    final roles = ref.read(sessionProvider)?.roles ?? const <AppRole>{};
    if (roles.contains(role)) state = role;
  }
}
