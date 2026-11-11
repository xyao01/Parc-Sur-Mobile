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
    this.departureCheckDone = false,
    this.returnCheckDone = false,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    final v = Map<String, dynamic>.from(json['vehicule'] as Map);
    return Mission(
      id: json['id'] as String,
      number: (json['numero'] as String?) ?? '',
      destination: (json['destination'] as String?) ?? '',
      purpose: json['motif'] as String?,
      vehicle: Vehicle(
        id: v['id'] as String,
        name: ((v['nom'] as String?) ?? '').trim(),
        plate: (v['immatriculation'] as String?) ?? '',
        odometerKm: (v['kilometrage'] as num?)?.toInt(),
      ),
      departure: DateTime.parse(json['depart'] as String).toLocal(),
      plannedReturn: DateTime.parse(json['retour'] as String).toLocal(),
      requester: (json['demandeur'] as String?) ?? '',
      passengers: (json['passagers'] as num?)?.toInt() ?? 0,
      departureCheckDone: json['controleDepart'] != null,
      returnCheckDone: json['controleRetour'] != null,
    );
  }

  final String id;

  /// Request number, e.g. `D-0139`.
  final String number;
  final String destination;
  final String? purpose;
  final Vehicle vehicle;
  final DateTime departure;
  final DateTime plannedReturn;
  final String requester;
  final int passengers;
  final bool departureCheckDone;
  final bool returnCheckDone;
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
