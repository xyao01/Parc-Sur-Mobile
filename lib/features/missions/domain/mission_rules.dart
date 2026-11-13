import 'mission.dart';
import 'mission_flow_config.dart';

/// The departure check (C05) can be done from midnight of the departure day,
/// minus [MissionFlowConfig.departureCheckOpensDaysBefore] days.
bool departureCheckOpen(Mission m, DateTime now) {
  final d = m.departure;
  final opens = DateTime(d.year, d.month, d.day - MissionFlowConfig.departureCheckOpensDaysBefore);
  return !now.isBefore(opens);
}
