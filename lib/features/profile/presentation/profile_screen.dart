import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/app_role.dart';
import '../../../core/features.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/maintenance_screen.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parcsur_logo.dart';
import '../../auth/application/session.dart';
import '../../auth/domain/mobile_profile.dart';
import '../../missions/presentation/chauffeur_nav.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../../requests/presentation/demandeur_nav.dart';
import '../data/profile_providers.dart';
import 'account_sheet.dart';

/// Version shown in the Profile (same as `pubspec.yaml`).
const appVersion = '1.0.0';

/// Mob-P01 · Profil (chauffeur et demandeur), validated proposal.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  Future<void> _askSignOut() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: ParcColors.scrim,
      builder: (sheet) => Semantics(
        container: true,
        label: 'Se déconnecter',
        child: Container(
          decoration: const BoxDecoration(
            color: ParcColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 22, 20, 24 + MediaQuery.paddingOf(sheet).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text('Se déconnecter ?', style: parcText(20, weight: 800))),
              const SizedBox(height: 14),
              Text(
                'Vous devrez saisir à nouveau votre adresse e-mail et votre mot de passe.',
                style: parcText(14, color: ParcColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 14),
              JourneyActionButton(
                label: 'Se déconnecter',
                danger: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
              const SizedBox(height: 14),
              ParcOutlinedButton(label: 'Annuler', height: 48, onPressed: () => Navigator.of(sheet).pop(false)),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    // The local session is closed even if the server cannot be reached.
    await ref.read(sessionProvider.notifier).signOut();
    if (mounted) context.go(Routes.login);
  }

  void _switchTo(AppRole role) {
    ref.read(activeSpaceProvider.notifier).select(role);
    context.go(role == AppRole.chauffeur ? Routes.missions : Routes.requesterHome);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionProvider);
    if (profile == null) return const Scaffold(backgroundColor: ParcColors.background);
    final space = ref.watch(activeSpaceProvider) ?? profile.roles.first;
    final both = profile.roles.length > 1;

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
                  if (both) ...[
                    const SectionCaps('Mon espace'),
                    const SizedBox(height: 12),
                    SegmentedChoice(
                      labels: const ['Espace chauffeur', 'Espace demandeur'],
                      selected: space == AppRole.chauffeur ? 0 : 1,
                      selectedColors: const [ParcColors.primary, ParcColors.primary],
                      onChanged: (i) => _switchTo(i == 0 ? AppRole.chauffeur : AppRole.demandeur),
                    ),
                    const SizedBox(height: 8),
                    Text("Changez d'espace sans vous déconnecter.", style: parcText(12, color: ParcColors.textMuted)),
                    const SizedBox(height: 20),
                  ],
                  const SectionCaps('Mes informations'),
                  const SizedBox(height: 12),
                  space == AppRole.chauffeur ? const _DriverDetails() : _RequesterDetails(profile: profile),
                  const SizedBox(height: 20),
                  const SectionCaps('Sécurité'),
                  const SizedBox(height: 12),
                  WhiteCard(
                    radius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _LinkRow(
                      icon: ParcIcons.lock,
                      label: 'Changer mon mot de passe',
                      onTap: () => context.push(Routes.changePassword),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Besoin d'aide ? Contactez l'administrateur de ParcSûr.",
                    textAlign: TextAlign.center,
                    style: parcText(13, color: ParcColors.textMuted, height: 1.5),
                  ),
                  Text(
                    'Version $appVersion',
                    textAlign: TextAlign.center,
                    style: parcText(13, color: ParcColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  _busy
                      ? const Center(child: CircularProgressIndicator(color: ParcColors.danger))
                      : _SignOutButton(onPressed: _askSignOut),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: space == AppRole.chauffeur
          ? const ChauffeurBottomNav(currentIndex: 3)
          : const DemandeurBottomNav(currentIndex: 3),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final MobileProfile profile;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: ParcColors.navy,
      padding: EdgeInsets.fromLTRB(20, 22 + top, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [ParcSurMark(size: 28), SizedBox(width: 8), ParcSurWordmark(fontSize: 18)]),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: ParcColors.headerChip, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(profile.initials, style: parcText(22, weight: 800, color: ParcColors.surface)),
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final role in profile.roles)
                          StatusChip(
                            role == AppRole.chauffeur ? 'Chauffeur' : 'Demandeur',
                            bg: ParcColors.headerChip,
                            fg: ParcColors.surface,
                          ),
                      ],
                    ),
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

/// Driver: `ma_fiche_chauffeur`; name and phone editable, the licence stays with the manager.
class _DriverDetails extends ConsumerWidget {
  const _DriverDetails();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(driverDetailsProvider);
    final d = async.value;
    final until = d?.validUntil;
    final reportWired = ref.watch(featuresProvider).driverRecordReport;
    final profile = ref.watch(sessionProvider)!;
    return _DetailsCard(
      loading: async.isLoading && !async.hasValue,
      failed: async.hasError && !async.hasValue,
      onRetry: () => ref.invalidate(driverDetailsProvider),
      rows: [
        ('Téléphone', d?.phone ?? '—'),
        ('Permis', d == null || d.licences.isEmpty ? '—' : d.licences.join(', ')),
        ('Fin de validité', until == null ? '—' : FrenchDates.date(until)),
      ],
      actions: [
        ('Modifier mes coordonnées', () => showDriverAccountSheet(context, profile: profile, details: d)),
        (
          'Signaler une erreur à mon gestionnaire',
          reportWired ? () {} : () => openMaintenance(context, 'Signaler une erreur'),
        ),
      ],
    );
  }
}

class _RequesterDetails extends ConsumerWidget {
  const _RequesterDetails({required this.profile});

  final MobileProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accountDetailsProvider);
    final d = async.value;
    return _DetailsCard(
      loading: async.isLoading && !async.hasValue,
      failed: async.hasError && !async.hasValue,
      onRetry: () => ref.invalidate(accountDetailsProvider),
      rows: [('Téléphone', d?.phone ?? '—'), ('Fonction', d?.function ?? '—'), ('Localisation', d?.location ?? '—')],
      actions: [('Modifier mes coordonnées', () => showAccountSheet(context, profile: profile, details: d))],
    );
  }
}

/// « Mes informations » card of Mob-P01: label/value rows, then action links.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.rows,
    required this.actions,
  });

  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final List<(String, String)> rows;
  final List<(String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: ParcColors.primary)),
      );
    }
    if (failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ParcErrorAlert(message: 'Impossible de charger vos informations.'),
          const SizedBox(height: 12),
          ParcOutlinedButton(label: 'Réessayer', height: 46, onPressed: onRetry),
        ],
      );
    }
    return WhiteCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: ParcColors.dividerSoft)),
              ),
              child: Row(
                children: [
                  Text(r.$1, style: parcText(13, weight: 600, color: ParcColors.textMuted)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(r.$2, textAlign: TextAlign.right, style: parcText(14, weight: 800)),
                  ),
                ],
              ),
            ),
          for (final (i, a) in actions.indexed)
            Container(
              decoration: i == actions.length - 1
                  ? null
                  : const BoxDecoration(
                      border: Border(bottom: BorderSide(color: ParcColors.dividerSoft)),
                    ),
              child: Semantics(
                button: true,
                child: InkWell(
                  onTap: a.$2,
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(a.$1, style: parcText(14, weight: 800, color: ParcColors.primary)),
                        ),
                        const ParcIcon(ParcIcons.chevronRight, size: 18, color: ParcColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: ParcColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: ParcIcon(icon, size: 18, color: ParcColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: parcText(14, weight: 700))),
              const ParcIcon(ParcIcons.chevronRight, size: 18, color: ParcColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: ParcColors.dangerBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: ParcColors.dangerBorder, width: 1.5),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ParcIcon(ParcIcons.logout, size: 18, color: ParcColors.danger),
                const SizedBox(width: 8),
                Text('Se déconnecter', style: parcText(15, weight: 800, color: ParcColors.danger)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
