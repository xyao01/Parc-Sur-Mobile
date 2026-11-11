/// A driver mission (approved request with an assigned vehicle).
class Mission {
  const Mission({
    required this.id,
    required this.origin,
    required this.destination,
    required this.vehicle,
    required this.departure,
    required this.plannedReturn,
    required this.requester,
    required this.passengers,
  });

  final String id;
  final String origin;
  final String destination;

  /// Assigned vehicle, `null` while the fleet manager has not confirmed it.
  final Vehicle? vehicle;
  final DateTime departure;
  final DateTime plannedReturn;
  final String requester;
  final int passengers;
}

class Vehicle {
  const Vehicle({required this.model, required this.plate, this.lastOdometer});

  final String model;
  final String plate;
  final OdometerReading? lastOdometer;

  /// `Land Cruiser · 1150 FB 01`
  String get label => '$model · $plate';
}

class OdometerReading {
  const OdometerReading({required this.km, required this.date});

  final int km;
  final DateTime date;
}

