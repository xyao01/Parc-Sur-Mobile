import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_icon.dart';
import 'journey_widgets.dart';
import 'mission_loader.dart';

/// Mob-C03 · Détails de la mission (request awaiting the driver's answer).
class MissionDetailsScreen extends StatelessWidget {
  const MissionDetailsScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context) {
    return MissionLoader(
      missionId: missionId,
      builder: (context, m) {
        final days = m.durationDays;
        return JourneyScaffold(
          header: JourneyHeader(
            title: 'Détails de la mission',
            subtitle: '${m.number} · ${stepLabel(3)}',
            onBack: () => journeyBack(context),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: ParcColors.pendingBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const ParcIcon(ParcIcons.clock, size: 18, color: ParcColors.pendingText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('En attente de votre réponse', style: parcText(13, weight: 700, color: ParcColors.pendingText)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // No origin in the database: destination only (see README).
                    Text(m.destination, style: parcText(20, weight: 800)),
                    if (m.purpose != null) ...[
                      const SizedBox(height: 12),
                      Text(m.purpose!, style: parcText(14, color: ParcColors.textSecondary, height: 1.5)),
                    ],
                    const SizedBox(height: 12),
                    DetailsGrid(entries: [
                      ('Départ', FrenchDates.shortDayTime(m.departure), color: null),
                      ('Retour prévu', FrenchDates.shortDayTime(m.plannedReturn), color: null),
                      ('Durée', '$days jour${days > 1 ? 's' : ''}', color: null),
                      ('Passagers', '${m.passengers}', color: null),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionCaps('Véhicule'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: ParcColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: const ParcIcon(ParcIcons.car, size: 24, color: ParcColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.vehicle.name, style: parcText(15, weight: 800)),
                              Text(m.vehicle.plate, style: parcText(13, color: ParcColors.textMuted)),
                            ],
                          ),
                        ),
                        // « Disponible » badge of the prototype: vehicle status not returned by the database.
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionCaps('Demandeur'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        InitialsAvatar(m.requester),
                        const SizedBox(width: 12),
                        // The requester's department (« [Direction du demandeur] ») is not returned by the database.
                        Expanded(child: Text(m.requester, style: parcText(15, weight: 800))),
                        if (m.requesterPhone != null) CallButton(label: 'Appeler ${m.requester}'),
                      ],
                    ),
                    if (m.notes != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: ParcColors.background, borderRadius: BorderRadius.circular(10)),
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: 'Précisions : ', style: parcText(13, weight: 800, color: ParcColors.textSecondary, height: 1.5)),
                            TextSpan(text: m.notes, style: parcText(13, color: ParcColors.textSecondary, height: 1.5)),
                          ]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          footer: [
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: Semantics(
                    button: true,
                    child: Material(
                      color: ParcColors.dangerBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: ParcColors.dangerBorder, width: 1.5),
                      ),
                      child: InkWell(
                        onTap: () => context.push(Routes.requestResponse(m.id, accept: false)),
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 54,
                          child: Center(child: Text('Refuser', style: parcText(15, weight: 800, color: ParcColors.danger))),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 14,
                  child: JourneyActionButton(
                    label: 'Accepter',
                    onPressed: () => context.push(Routes.requestResponse(m.id, accept: true)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
