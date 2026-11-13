import '../../../app/routes.dart';
import 'app_alert.dart';

/// Mobile screen of an alert (l2-not-03 « lien vers l'élément concerné »).
///
/// The database stores web links: `/mes-demandes?id=…` (requester) → request detail (Mob-D06, which leads
/// to the decision and the tracking); mission alerts of a driver carry no link → Planning (Mob-C11).
/// Links with no mobile screen (vehicles, manager pages) → `null`: the alert is only marked read.
String? alertRoute(AppAlert alert) {
  final link = alert.link;
  if (link == null || link.isEmpty) {
    final mission = alert.kind != AlertKind.warning && alert.title.toLowerCase().contains('mission');
    return alert.audience == AlertAudience.driver && mission ? Routes.planning : null;
  }
  final uri = Uri.tryParse(link);
  if (uri == null) return null;
  final id = uri.queryParameters['id'];
  return switch (uri.path) {
    '/mes-demandes' when alert.audience == AlertAudience.requester =>
      id == null || id.isEmpty ? Routes.myRequests : Routes.requestDetail(id),
    '/missions' when alert.audience == AlertAudience.driver => Routes.planning,
    _ => null,
  };
}
