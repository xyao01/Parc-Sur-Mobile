/// Port over the driver mission calls, so screens can be tested without Supabase.
abstract interface class MissionsGateway {
  /// `mes_missions_chauffeur()`: missions of the signed-in driver.
  Future<List<Map<String, dynamic>>> myMissions();

  /// Requests waiting for the driver's answer (Mob-C01…C04).
  /// No such step in the database yet: the Supabase gateway returns none.
  Future<List<Map<String, dynamic>>> pendingRequests();

  /// Accept / refuse a request (Mob-C04). Not offered by the database yet.
  Future<void> respondToRequest({required String missionId, required bool accept, String? reason, String? details});

  /// Incident during the mission, or departure blocked (Mob-C06, C07). Not offered by the database yet.
  Future<void> reportIncident({
    required String missionId,
    required String kind,
    String? description,
    required bool blocksDeparture,
  });

  /// Puts a ticket photo in the `justificatifs` storage at [remotePath] (`carburant/<fill-up id>/…`).
  /// A copy already there (resend) is not an error.
  Future<void> uploadTicket({required String localPath, required String remotePath});

  /// `saisir_plein_chauffeur(...)`: fill-up during the mission (Mob-C13). Idempotent on [id].
  Future<void> recordFuel({
    required String id,
    required String missionId,
    required int odometerKm,
    required double litres,
    required int amount,
    required bool full,
    String? station,
    required List<String> tickets,
    required DateTime enteredAt,
  });

  /// `enregistrer_controle(...)`: departure / return check. Idempotent on [id].
  Future<void> recordControl({
    required String id,
    required String missionId,
    required String type,
    required int odometerKm,
    required String fuel,
    required Map<String, String> points,
    String? observations,
    required DateTime enteredAt,
  });
}

/// Refusal with a message meant for the user (the database raises French messages).
class MissionsGatewayException implements Exception {
  const MissionsGatewayException(this.message, {this.network = false});

  final String message;
  final bool network;

  @override
  String toString() => 'MissionsGatewayException($message)';
}
