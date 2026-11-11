/// Configurable parameters of the departure check.
///
/// Business rules not settled yet are kept here, not hard-coded in the UI
/// (see README, « Points ouverts »).
abstract final class DepartureCheckConfig {
  /// Fuel gauge choices, in order.
  static const fuelLevels = ['1/4', '1/2', '3/4', 'Plein'];

  /// Pre-selected fuel level.
  static const defaultFuelLevel = '3/4';

  /// Vehicle condition checklist. Expected to come from a référentiel later.
  static const checklist = [
    'Pneus et roue de secours',
    'Feux et clignotants',
    'Carrosserie sans nouveau dommage',
    'Documents à bord',
  ];

  /// Progress indicator of the departure flow (prototype shows step 2 of 3).
  static const currentStep = 2;
  static const totalSteps = 3;
}
