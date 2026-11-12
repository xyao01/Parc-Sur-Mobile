import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../missions/presentation/journey_widgets.dart';
import 'request_widgets.dart';

/// Mob-D07 · Décision du gestionnaire: validated (vehicle, driver) or refused (reason).
/// The prototype's « Validée / Refusée » switch only shows both states: the app shows the actual decision.
class RequestDecisionScreen extends StatelessWidget {
  const RequestDecisionScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return RequestLoader(
      requestId: requestId,
      builder: (context, r, now) {
        final when = '${r.destination} · ${FrenchDates.shortDay(r.departure, capitalize: false)} ${FrenchDates.time(r.departure)}';
        final refused = r.status == 'refusee';
        final validated = r.status == 'validee';
        final Widget body;
        final List<Widget> footer;
        if (validated) {
          body = ResultView(
            icon: ParcIcons.checkBold,
            iconBg: ParcColors.successBg,
            iconColor: ParcColors.success,
            topPadding: 24,
            title: 'Demande validée',
            message: Text(
              '$when. ${r.driver != null ? 'Un véhicule et un chauffeur vous sont affectés.' : 'Un véhicule vous est affecté.'}',
              textAlign: TextAlign.center,
              style: parcText(14, color: ParcColors.textSecondary, height: 1.5),
            ),
            child: WhiteCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  if (r.vehicle != null)
                    _Line(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: ParcColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: const ParcIcon(ParcIcons.car, size: 24, color: ParcColors.primary),
                      ),
                      label: 'Véhicule',
                      value: r.vehicle!,
                    ),
                  if (r.driver != null)
                    _Line(
                      leading: InitialsAvatar(r.driver!),
                      label: 'Chauffeur',
                      value: r.driver!,
                      // Driver's phone is not in demande_vue: call button shown, not wired (see README).
                      trailing: const CallButton(label: 'Appeler le chauffeur'),
                    ),
                  // « · [Lieu de prise en charge] » of the prototype: not stored in the database.
                  _Line(label: 'Rendez-vous de départ', value: FrenchDates.shortDayTime(r.departure), last: true),
                ],
              ),
            ),
          );
          footer = [
            ParcPrimaryButton(label: 'Suivre ma mission', onPressed: () => context.push(Routes.requestTracking(r.id))),
            ParcOutlinedButton(label: "Retour à l'accueil", height: 48, onPressed: () => context.go(Routes.requesterHome)),
          ];
        } else if (refused) {
          body = ResultView(
            icon: ParcIcons.cross,
            iconBg: ParcColors.dangerSoft,
            iconColor: ParcColors.danger,
            iconSize: 40,
            topPadding: 24,
            title: 'Demande refusée',
            message: Text('$when.', textAlign: TextAlign.center, style: parcText(14, color: ParcColors.textSecondary, height: 1.5)),
            child: WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Motif du refus', style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                  const SizedBox(height: 8),
                  Text(r.refusalReason ?? 'Non précisé', style: parcText(15, weight: 800)),
                ],
              ),
            ),
          );
          footer = [
            ParcPrimaryButton(label: 'Refaire une demande', onPressed: () => context.push(Routes.newRequest)),
            ParcOutlinedButton(label: "Retour à l'accueil", height: 48, onPressed: () => context.go(Routes.requesterHome)),
          ];
        } else {
          body = Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              r.status == 'annulee' ? 'Cette demande a été annulée.' : 'Le gestionnaire n’a pas encore décidé.',
              textAlign: TextAlign.center,
              style: parcText(15, color: ParcColors.textSecondary),
            ),
          );
          footer = [ParcPrimaryButton(label: "Retour à l'accueil", onPressed: () => context.go(Routes.requesterHome))];
        }
        return JourneyScaffold(
          header: JourneyHeader(
            title: 'Décision du gestionnaire',
            subtitle: '${r.number} · ${stepLabel(7)}',
            backLabel: 'Retour à la demande',
            onBack: () => requestBack(context, Routes.myRequests),
          ),
          bodyPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          body: body,
          footer: footer,
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.leading, this.trailing, this.last = false});

  final String label;
  final String value;
  final Widget? leading;
  final Widget? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: ParcColors.dividerSoft)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                Text(value, style: parcText(15, weight: 800)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
