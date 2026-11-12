/// A driver mission, as returned by `mes_missions_chauffeur()`
/// (validated request with an assigned vehicle, not yet closed).
class Mission {
  const Mission({
    required this.id,
    required this.number,
    required this.destination,
    required this.vehicle,
    required this.departure,
    required this.plannedReturn,
    required this.requester,
    required this.passengers,
    this.purpose,
    this.notes,
    this.requesterPhone,
    this.departureCheck,
    this.returnCheck,
    this.receivedAt,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    final v = Map<String, dynamic>.from(json['vehicule'] as Map);
    String? text(String key) {
      final s = (json[key] as String?)?.trim();
      return s == null || s.isEmpty ? null : s;
    }

    return Mission(
      id: json['id'] as String,
      number: (json['numero'] as String?) ?? '',
      destination: (json['destination'] as String?) ?? '',
      purpose: text('motif'),
      notes: text('commentaire'),
      vehicle: Vehicle(
        id: v['id'] as String,
        name: ((v['nom'] as String?) ?? '').trim(),
        plate: (v['immatriculation'] as String?) ?? '',
        odometerKm: (v['kilometrage'] as num?)?.toInt(),
      ),
      departure: DateTime.parse(json['depart'] as String).toLocal(),
      plannedReturn: DateTime.parse(json['retour'] as String).toLocal(),
      requester: (json['demandeur'] as String?) ?? '',
      requesterPhone: text('telephoneDemandeur'),
      passengers: (json['passagers'] as num?)?.toInt() ?? 0,
      departureCheck: ControlSummary.fromJson(json['controleDepart']),
      returnCheck: ControlSummary.fromJson(json['controleRetour']),
      receivedAt: json['recueLe'] is String ? DateTime.parse(json['recueLe'] as String).toLocal() : null,
    );
  }

  final String id;

  /// Request number, e.g. `D-0139`.
  final String number;
  final String destination;
  final String? purpose;

  /// Requester's « Précisions » (`commentaire`).
  final String? notes;
  final Vehicle vehicle;
  final DateTime departure;
  final DateTime plannedReturn;
  final String requester;
  final String? requesterPhone;
  final int passengers;

  /// Departure / return checks recorded with `enregistrer_controle`.
  final ControlSummary? departureCheck;
  final ControlSummary? returnCheck;

  /// When a request awaiting the driver's answer was received (pending requests only).
  final DateTime? receivedAt;

  bool get departureCheckDone => departureCheck != null;
  bool get returnCheckDone => returnCheck != null;

  /// Left (departure check recorded) and not back yet.
  bool get inProgress => departureCheckDone && !returnCheckDone;

  /// Calendar days covered, departure and return days included (« 3 jours »).
  int get durationDays {
    final a = DateTime(departure.year, departure.month, departure.day);
    final b = DateTime(plannedReturn.year, plannedReturn.month, plannedReturn.day);
    return b.difference(a).inDays + 1;
  }
}

/// A recorded departure / return check (`controleDepart`, `controleRetour`).
class ControlSummary {
  const ControlSummary({this.at, this.odometerKm});

  static ControlSummary? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = json['saisiLe'];
    return ControlSummary(
      at: at is String ? DateTime.parse(at).toLocal() : null,
      odometerKm: (json['kilometrage'] as num?)?.toInt(),
    );
  }

  final DateTime? at;
  final int? odometerKm;
}

class Vehicle {
  const Vehicle({required this.id, required this.name, required this.plate, this.odometerKm});

  final String id;

  /// Brand + model, e.g. `Toyota Land Cruiser`.
  final String name;
  final String plate;

  /// Current odometer of the vehicle (last accepted reading).
  final int? odometerKm;

  /// `Land Cruiser · 1150 FB 01`
  String get label => '$name · $plate';
}
