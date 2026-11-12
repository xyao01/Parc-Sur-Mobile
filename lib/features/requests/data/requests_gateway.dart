/// Port over the requester calls (Mob-D01…D10), so screens can be tested without Supabase.
abstract interface class RequestsGateway {
  /// `demande_vue`, own requests only (`demandeur_id = utilisateur_courant()`), newest first.
  Future<List<Map<String, dynamic>>> myRequests();

  /// Insert into `demande_vehicule` (checked by the `controler_demande` trigger). Returns the new id.
  Future<String> create(Map<String, dynamic> row);

  /// Update of a pending request by its requester (RLS `demande_modification`).
  Future<void> update(String id, Map<String, dynamic> row);

  /// `annuler_demande(id, motif)`.
  Future<void> cancel(String id, String reason);

  /// Problem reported during the mission (Mob-D08). Not offered by the database yet.
  Future<void> reportProblem({required String requestId, required String kind, String? description});

  /// Evaluation of the mission (Mob-D10). Not offered by the database yet.
  Future<void> rate({required String requestId, required int rating, required List<String> tags, String? comment});
}

class RequestsGatewayException implements Exception {
  const RequestsGatewayException(this.message);

  final String message;

  @override
  String toString() => 'RequestsGatewayException($message)';
}
