import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../domain/vehicle_request.dart';
import 'request_widgets.dart';

/// Mob-D09 · Fin de mission (requester confirmation before the evaluation).
/// Actual arrival time, distance and damage are not readable by the requester: planned values only (see README).
class RequestEndScreen extends StatelessWidget {
  const RequestEndScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) =>
      RequestLoader(requestId: requestId, builder: (context, r, now) => _End(request: r));
}

class _End extends StatefulWidget {
  const _End({required this.request});

  final VehicleRequest request;

  @override
  State<_End> createState() => _EndState();
}

class _EndState extends State<_End> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return JourneyScaffold(
      header: JourneyHeader(
        title: 'Fin de mission',
        subtitle: '${r.number} · ${stepLabel(9)}',
        backLabel: 'Retour au suivi',
        onBack: () => requestBack(context, Routes.myRequests),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: ParcColors.successBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: ParcColors.success, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const ParcIcon(ParcIcons.checkBold, size: 22, color: ParcColors.surface),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mission terminée', style: parcText(16, weight: 800)),
                      // Prototype: « Le chauffeur a clôturé la mission. » — the closure is not readable by the requester.
                      Text('Le retour prévu est passé.', style: parcText(13, weight: 600, color: ParcColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(r.destination, style: parcText(18, weight: 800)),
                const SizedBox(height: 12),
                const Divider(height: 1, color: ParcColors.dividerSoft),
                const SizedBox(height: 12),
                DetailsGrid(valueWeight: 800, entries: [
                  ('Départ', FrenchDates.shortDayTime(r.departure), color: null),
                  ('Retour', FrenchDates.shortDayTime(r.plannedReturn), color: null),
                  ('Véhicule', r.vehicle ?? '—', color: null),
                  ('Chauffeur', r.driver ?? 'Sans chauffeur', color: null),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ConfirmBox(
            text: "Je confirme que la mission s'est déroulée comme prévu.",
            checked: _confirmed,
            onTap: () => setState(() => _confirmed = !_confirmed),
          ),
        ],
      ),
      footer: [
        _confirmed
            ? JourneyActionButton(label: 'Continuer', onPressed: () => context.push(Routes.requestRating(r.id)))
            : JourneyActionButton(label: 'Cochez la confirmation pour continuer', ready: false, onPressed: () {}),
      ],
    );
  }
}
