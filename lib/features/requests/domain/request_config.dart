/// Configurable parameters of a vehicle request (see README, « Points ouverts »).
abstract final class RequestConfig {
  /// Minimum number of passengers (the requester counts as one).
  static const minPassengers = 1;

  /// Maximum number of passengers: same limit as the database and the web app (`PASSAGERS_MAX`).
  static const maxPassengers = 50;

  /// « Besoin d'un chauffeur » default value.
  static const needDriverByDefault = true;

  /// `annuler_demande` requires a reason; Mob-D06 asks none. Sent as is to the managers.
  static const cancelReason = 'Annulée par le demandeur depuis l’application mobile.';

  /// Mob-D08 « Signaler un problème » kinds.
  static const problemKinds = ['Retard important', 'Changement de trajet', 'Comportement du chauffeur', 'Autre'];

  /// Mob-D10 evaluation tags.
  static const ratingTags = ['Ponctualité', 'Propreté du véhicule', 'Conduite prudente', 'Courtoisie'];
}
