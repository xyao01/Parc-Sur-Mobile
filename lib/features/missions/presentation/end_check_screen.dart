import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../data/missions_providers.dart';
import '../domain/mission.dart';
import '../domain/mission_drafts.dart';
import '../domain/mission_flow_config.dart';
import 'journey_widgets.dart';
import 'mission_loader.dart';

/// Mob-C09 · Contrôle de fin de mission. Entries are sent with the return check at Mob-C10.
class EndCheckScreen extends StatelessWidget {
  const EndCheckScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context) => MissionLoader(missionId: missionId, builder: (context, m) => _EndCheck(mission: m));
}

class _EndCheck extends ConsumerStatefulWidget {
  const _EndCheck({required this.mission});

  final Mission mission;

  @override
  ConsumerState<_EndCheck> createState() => _EndCheckState();
}

class _EndCheckState extends ConsumerState<_EndCheck> {
  late final ReturnDraft _draft = ref.read(returnDraftProvider(widget.mission.id));
  late final TextEditingController _damage = TextEditingController(text: _draft.damageDescription)
    ..addListener(() => _draft.damageDescription = _damage.text);

  @override
  void dispose() {
    _damage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    return JourneyScaffold(
      offlineBanner: true,
      header: JourneyHeader(
        title: 'Contrôle de fin de mission',
        subtitle: m.vehicle.label,
        backLabel: "Retour à l'arrivée",
        onBack: () => journeyBack(context),
      ),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // « (départ : 3/4) » of the prototype: the departure fuel level is not returned by mes_missions_chauffeur.
          const FieldCaption("Niveau de carburant à l'arrivée"),
          const SizedBox(height: 8),
          FuelSelector(selected: _draft.fuel, onChanged: (v) => setState(() => _draft.fuel = v)),
          const SizedBox(height: 16),
          const FieldCaption('État du véhicule au retour'),
          const SizedBox(height: 8),
          for (final (i, c) in MissionFlowConfig.returnChecklist.indexed) ...[
            if (i > 0) const SizedBox(height: 6),
            ChecklistItem(
              label: c.label,
              checked: _draft.checked.contains(c.label),
              onTap: () => setState(() => _draft.checked.contains(c.label) ? _draft.checked.remove(c.label) : _draft.checked.add(c.label)),
            ),
          ],
          const SizedBox(height: 16),
          const FieldCaption('Dommages constatés'),
          const SizedBox(height: 8),
          SegmentedChoice(
            labels: const ['Aucun dommage', 'Signaler un dommage'],
            selected: _draft.damage ? 1 : 0,
            selectedColors: const [ParcColors.success, ParcColors.danger],
            onChanged: (i) => setState(() => _draft.damage = i == 1),
          ),
          if (_draft.damage) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final zone in MissionFlowConfig.damageZones)
                  PillChoice(
                    label: zone,
                    selected: _draft.damageZone == zone,
                    selectedColor: ParcColors.danger,
                    onTap: () => setState(() => _draft.damageZone = zone),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ParcTextField(
              key: const Key('endCheck.damage'),
              controller: _damage,
              height: null,
              maxLines: 2,
              fontSize: 15,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              hintText: 'Décrivez le dommage (rayure, impact, bris de glace…)',
              semanticLabel: 'Description du dommage',
            ),
          ],
          const SizedBox(height: 16),
          const FieldCaption('Photos de fin de mission'),
          const SizedBox(height: 8),
          const PhotoStrip(),
        ],
      ),
      footer: [
        ParcPrimaryButton(label: 'Continuer vers la clôture', onPressed: () => context.push(Routes.closure(m.id))),
      ],
    );
  }
}
