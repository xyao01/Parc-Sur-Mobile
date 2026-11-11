/// Configurable parameters of the departure check (see README, « Points ouverts »).
abstract final class DepartureCheckConfig {
  /// Fuel gauge choices (label shown → value stored by `enregistrer_controle`).
  /// The database also accepts `vide`, not offered by the prototype.
  static const fuelLevels = {
    '1/4': 'quart',
    '1/2': 'moitie',
    '3/4': 'trois_quarts',
    'Plein': 'plein',
  };

  /// Pre-selected fuel level.
  static const defaultFuelLevel = '3/4';

  /// Vehicle condition checklist (label shown → control point key in the database,
  /// see `libelle_point_controle`).
  static const checklist = {
    'Pneus et roue de secours': 'pneus',
    'Feux et clignotants': 'eclairage',
    'Carrosserie sans nouveau dommage': 'carrosserie',
    'Documents à bord': 'documents',
  };

  /// Value stored for a checked / unchecked item. An unchecked item is reported
  /// as an anomaly (the server then notifies the fleet managers).
  static const checkedValue = 'ok';
  static const uncheckedValue = 'anomalie';

  /// Progress indicator of the departure flow (prototype shows step 2 of 3).
  static const currentStep = 2;
  static const totalSteps = 3;
}
