/// Configurable parameters of a vehicle request (see README, « Points ouverts »).
abstract final class RequestConfig {
  /// Minimum number of passengers (the requester counts as one).
  static const minPassengers = 1;

  /// Maximum number of passengers; `null` = no limit until the fleet rule is set.
  static const int? maxPassengers = null;

  /// « Besoin d'un chauffeur » default value.
  static const needDriverByDefault = true;
}
