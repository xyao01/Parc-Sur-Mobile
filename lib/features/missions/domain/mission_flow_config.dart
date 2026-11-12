/// One line of a vehicle checklist: label and hint shown, control point keys stored
/// by `enregistrer_controle` (see `libelle_point_controle` in the database).
class CheckPoint {
  const CheckPoint(this.label, this.keys, {this.hint});

  final String label;
  final String? hint;
  final List<String> keys;
}

/// Configurable parameters of the driver journey Mob-C01…C10 (see README, « Points ouverts »).
abstract final class MissionFlowConfig {
  /// Steps of the journey shown in the headers (« Étape 5 sur 10 »).
  static const totalSteps = 10;

  /// Fuel gauge choices (label shown → value stored by `enregistrer_controle`).
  /// The database also accepts `vide`, not offered by the prototype.
  static const fuelLevels = {'1/4': 'quart', '1/2': 'moitie', '3/4': 'trois_quarts', 'Plein': 'plein'};
  static const defaultFuelLevel = '3/4';

  /// Mob-C05 « Vérification du véhicule ». « Propreté et équipements » covers two database points.
  static const departureChecklist = [
    CheckPoint('Pneus et roue de secours', ['pneus'], hint: 'Pression et usure visuelle'),
    CheckPoint('Feux et clignotants', ['eclairage'], hint: 'Avant, arrière, stop'),
    CheckPoint('Documents à bord', ['documents'], hint: 'Carte grise, assurance, visite technique'),
    CheckPoint('Carrosserie sans nouveau dommage', ['carrosserie'], hint: 'Faire le tour du véhicule'),
    CheckPoint('Propreté et équipements', ['proprete', 'equipements'], hint: 'Cric, triangle, trousse de secours'),
  ];

  /// Mob-C09 « État du véhicule au retour ».
  static const returnChecklist = [
    CheckPoint('Pneus et roue de secours', ['pneus']),
    CheckPoint('Feux et clignotants', ['eclairage']),
    CheckPoint('Carrosserie sans nouveau dommage', ['carrosserie']),
    CheckPoint('Documents et clés restitués', ['documents']),
  ];

  /// Value stored for a checked / unchecked item. An unchecked item is reported as an
  /// anomaly: the server then notifies the fleet managers.
  static const checkedValue = 'ok';
  static const uncheckedValue = 'anomalie';

  /// Mob-C04 refusal reasons.
  static const refusalReasons = [
    'Indisponible à ces dates',
    'Véhicule non adapté à la mission',
    'Raison de santé ou repos obligatoire',
    'Autre motif',
  ];

  /// Mob-C06 « Nature du problème » (departure blocked).
  static const blockingProblems = [
    'Panne mécanique',
    'Pneu endommagé',
    'Feux défectueux',
    'Documents manquants',
    'Dommage carrosserie',
    'Autre',
  ];

  /// Mob-C07 incident kinds.
  static const incidentKinds = ['Panne', 'Accident', 'Crevaison', 'Voyant moteur', 'Retard', 'Autre'];

  /// Mob-C09 damage zones.
  static const damageZones = ['Avant', 'Arrière', 'Côté gauche', 'Côté droit', 'Intérieur'];

  /// Shown when an action of the prototype has no backend yet (answer to a request,
  /// availability, incident, blocked departure). Wording not in the prototype.
  static const unavailableMessage =
      'Cette action n’est pas encore disponible sur le serveur. Prévenez votre gestionnaire de parc.';
}
