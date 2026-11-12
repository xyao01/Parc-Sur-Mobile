import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_icon.dart';
import 'journey_widgets.dart';
import 'mission_loader.dart';

/// Mob-C02 · Nouvelle demande reçue.
class NewRequestNoticeScreen extends StatelessWidget {
  const NewRequestNoticeScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context) {
    return MissionLoader(
      missionId: missionId,
      builder: (context, r) {
        final received = r.receivedAt;
        return JourneyScaffold(
          header: JourneyHeader(
            title: 'Notification',
            subtitle: stepLabel(2),
            backLabel: "Retour à l'accueil",
            onBack: () => journeyBack(context),
          ),
          bodyPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          body: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: ParcColors.pendingBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const ParcIcon(ParcIcons.bell, size: 34, color: ParcColors.pendingText),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text('Nouvelle demande de mission', textAlign: TextAlign.center, style: parcText(22, weight: 800)),
              ),
              const SizedBox(height: 4),
              if (received != null)
                Text(
                  "Reçue aujourd'hui à ${FrenchDates.time(received)} · à traiter",
                  textAlign: TextAlign.center,
                  style: parcText(13, color: ParcColors.textMuted),
                ),
              const SizedBox(height: 16),
              InfoRows(rows: [
                ('Destination', r.destination, color: null, size: 15),
                ('Véhicule', r.vehicle.label, color: null, size: 14),
                ('Départ', FrenchDates.shortDayTime(r.departure), color: null, size: 14),
                ('Retour', FrenchDates.shortDayTime(r.plannedReturn), color: null, size: 14),
                ('Demandeur', r.requester, color: null, size: 14),
                ('Passagers', '${r.passengers}', color: null, size: 14),
              ]),
            ],
          ),
          footer: [
            ParcPrimaryButton(
              label: 'Voir les détails de la mission',
              onPressed: () => context.push(Routes.requestDetails(r.id)),
            ),
            ParcOutlinedButton(label: 'Répondre plus tard', height: 48, onPressed: () => context.go(Routes.missions)),
          ],
        );
      },
    );
  }
}
