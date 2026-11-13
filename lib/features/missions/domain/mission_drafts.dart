import 'mission_flow_config.dart';

/// Entries kept between Mob-C05 « Préparation du départ » and Mob-C06 « Validation du départ ».
class DepartureDraft {
  int? odometerKm;
  String fuel = MissionFlowConfig.defaultFuelLevel;
  final Set<String> checked = {};

  /// `enregistrer_controle` points: every database key of the checklist → ok / anomalie.
  Map<String, String> get points => pointsFor(MissionFlowConfig.departureChecklist, checked);

  /// Checklist lines left unchecked (shown in the recap).
  List<String> get anomalies => [
    for (final c in MissionFlowConfig.departureChecklist)
      if (!checked.contains(c.label)) c.label,
  ];
}

/// Entries kept from Mob-C08 « Arrivée » to Mob-C10 « Clôture ».
class ReturnDraft {
  DateTime? arrivedAt;
  int? odometerKm;
  String fuel = MissionFlowConfig.defaultFuelLevel;
  final Set<String> checked = {for (final c in MissionFlowConfig.returnChecklist) c.label};
  bool damage = false;
  String? damageZone;
  String damageDescription = '';
  String observations = '';

  Map<String, String> get points => pointsFor(MissionFlowConfig.returnChecklist, checked);

  /// `p_observations`: damage reported in Mob-C09, then the driver's observations of Mob-C10.
  String? get observationsText {
    final parts = <String>[
      if (damage)
        [
          'Dommage constaté',
          ?damageZone,
          if (damageDescription.trim().isNotEmpty) damageDescription.trim(),
        ].join(' · '),
      if (observations.trim().isNotEmpty) observations.trim(),
    ];
    return parts.isEmpty ? null : parts.join('\n');
  }
}

Map<String, String> pointsFor(List<CheckPoint> checklist, Set<String> checked) => {
  for (final c in checklist)
    for (final key in c.keys)
      key: checked.contains(c.label) ? MissionFlowConfig.checkedValue : MissionFlowConfig.uncheckedValue,
};
