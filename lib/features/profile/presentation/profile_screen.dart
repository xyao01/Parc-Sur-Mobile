import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/app_role.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parcsur_logo.dart';
import '../../auth/application/session.dart';
import '../../auth/domain/mobile_profile.dart';
import '../../missions/presentation/chauffeur_nav.dart';
import '../../requests/presentation/demandeur_nav.dart';

/// Profil — signed-in user (from `profil_mobile()` and the Supabase account) and sign-out.
///
/// Not in the prototype: built only from existing design system pieces
/// (navy header of « Mes missions », white bordered cards, outlined button).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(sessionProvider.notifier).signOut();
    if (mounted) context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionProvider);
    if (profile == null) return const Scaffold(backgroundColor: ParcColors.background);

    final isDriver = profile.roles.contains(AppRole.chauffeur);
    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(profile: profile),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'MES ACCÈS',
                      style: parcText(13, weight: 800, color: ParcColors.textMuted, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: ParcColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ParcColors.divider),
                    ),
                    child: Column(
                      children: [
                        for (final (i, role) in profile.roles.indexed) ...[
                          if (i > 0) const Divider(height: 1, color: ParcColors.divider),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(child: Text(_roleLabel(role), style: parcText(15, weight: 700))),
                                Text(_roleDetail(role), style: parcText(13, color: ParcColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ParcOutlinedButton(label: 'Se déconnecter', onPressed: _busy ? null : _signOut),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          isDriver ? const ChauffeurBottomNav(currentIndex: 3) : const DemandeurBottomNav(currentIndex: 3),
    );
  }

  static String _roleLabel(AppRole role) => switch (role) {
        AppRole.chauffeur => 'Chauffeur',
        AppRole.demandeur => 'Demandeur',
      };

  static String _roleDetail(AppRole role) => switch (role) {
        AppRole.chauffeur => 'Missions',
        AppRole.demandeur => 'Demandes de véhicule',
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final MobileProfile profile;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: ParcColors.navy,
      padding: EdgeInsets.fromLTRB(20, 22 + top, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              ParcSurMark(size: 28),
              SizedBox(width: 8),
              ParcSurWordmark(fontSize: 18),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: ParcColors.headerChip, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(profile.initials, style: parcText(18, weight: 800, color: ParcColors.surface)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(profile.fullName, style: parcText(22, weight: 800, color: ParcColors.surface)),
                    ),
                    if (profile.email.isNotEmpty)
                      Text(profile.email, style: parcText(13, color: ParcColors.onDarkMuted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
