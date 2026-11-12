import 'request_config.dart';
import 'vehicle_request.dart';

/// Entries of Mob-D02, kept for Mob-D03 (new request, or edit of a pending one).
class RequestDraft {
  RequestDraft();

  /// Edit of a pending request: starts from its current values (once).
  void fillFrom(VehicleRequest r) {
    if (filled) return;
    filled = true;
    purpose = r.purpose;
    destination = r.destination;
    departure = r.departure;
    plannedReturn = r.plannedReturn;
    passengers = r.passengers;
    withDriver = r.withDriver;
    notes = r.notes ?? '';
  }

  bool filled = false;

  String purpose = '';
  String destination = '';
  DateTime? departure;
  DateTime? plannedReturn;
  int passengers = RequestConfig.minPassengers;
  bool withDriver = RequestConfig.needDriverByDefault;
  String notes = '';

  /// Errors by field, same checks and wording as the web app (`controleDemande`) and the database.
  Map<String, String> validate(DateTime now) {
    final e = <String, String>{};
    if (purpose.trim().isEmpty) e['purpose'] = 'Indiquez l’objet de la mission.';
    if (destination.trim().isEmpty) e['destination'] = 'Indiquez la destination, ex. Bouaké.';
    final d = departure;
    final r = plannedReturn;
    if (d == null) {
      e['departure'] = 'Indiquez la date et l’heure de départ.';
    } else if (d.isBefore(now)) {
      e['departure'] = 'Le départ ne peut pas être dans le passé.';
    }
    if (r == null) {
      e['return'] = 'Indiquez la date et l’heure de retour.';
    } else if (d != null && !r.isAfter(d)) {
      e['return'] = 'Le retour doit suivre le départ.';
    }
    if (passengers < RequestConfig.minPassengers || passengers > RequestConfig.maxPassengers) {
      e['passengers'] = 'Indiquez entre ${RequestConfig.minPassengers} et ${RequestConfig.maxPassengers} passagers.';
    }
    return e;
  }

  /// Columns of `demande_vehicule` (web `versDonneesDemande`).
  Map<String, dynamic> toRow() => {
        'motif': purpose.trim(),
        'destination': destination.trim(),
        'depart': departure!.toUtc().toIso8601String(),
        'retour': plannedReturn!.toUtc().toIso8601String(),
        'passagers': passengers,
        'avec_chauffeur': withDriver,
        'commentaire': notes.trim().isEmpty ? null : notes.trim(),
      };
}
