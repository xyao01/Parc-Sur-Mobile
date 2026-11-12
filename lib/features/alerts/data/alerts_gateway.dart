/// Port over the alert calls (Mob-C12), so the screen can be tested without Supabase.
/// Rows use the common shape `id`, `titre`, `message`, `lien`, `creeLe`, `lueLe`.
abstract interface class AlertsGateway {
  /// `mes_notifications_chauffeur()`: alerts of the signed-in driver.
  Future<List<Map<String, dynamic>>> driverAlerts();

  /// `marquer_notifications_chauffeur_lues(ids)`; all unread ones when [ids] is null.
  Future<void> markDriverAlertsRead(List<String>? ids);

  /// Table `notification` (RLS: rows of the signed-in web account): alerts of a requester.
  Future<List<Map<String, dynamic>>> requesterAlerts();

  /// Sets `lue_le` on the requester's alerts; all unread ones when [ids] is null.
  Future<void> markRequesterAlertsRead(List<String>? ids);
}

class AlertsGatewayException implements Exception {
  const AlertsGatewayException(this.message);

  final String message;

  @override
  String toString() => 'AlertsGatewayException($message)';
}
