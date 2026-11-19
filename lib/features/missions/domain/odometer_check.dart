import 'mission_flow_config.dart';

enum OdometerVerdict {
  /// Below the reference: refused by the database.
  low,

  /// Within [MissionFlowConfig.maxKmPerDay] per started day.
  ok,

  /// Beyond the ceiling: accepted, but the database flags the reading « à vérifier ».
  unusual,
}

/// Same rule as the database (`seuil_km_par_jour()`): at most [MissionFlowConfig.maxKmPerDay] per started day
/// since [since] (at least one day; one day when [since] is unknown).
OdometerVerdict checkOdometer({required int km, required int reference, DateTime? since, required DateTime now}) {
  if (km < reference) return OdometerVerdict.low;
  final minutes = since == null ? 0 : now.difference(since).inMinutes;
  final days = minutes <= 0 ? 1 : (minutes / Duration.minutesPerDay).ceil();
  return km - reference > MissionFlowConfig.maxKmPerDay * days ? OdometerVerdict.unusual : OdometerVerdict.ok;
}
