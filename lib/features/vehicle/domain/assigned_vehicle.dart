/// Vehicle assigned to the signed-in agent (`mon_vehicule()`).
class AssignedVehicle {
  const AssignedVehicle({
    required this.id,
    required this.name,
    required this.plate,
    required this.readings,
    required this.monthDone,
    this.odometerKm,
    this.month,
  });

  factory AssignedVehicle.fromJson(Map<String, dynamic> j) {
    final month = j['moisCourant'] is Map ? Map<String, dynamic>.from(j['moisCourant'] as Map) : const <String, dynamic>{};
    return AssignedVehicle(
      id: j['id'] as String,
      name: ((j['nom'] as String?) ?? '').trim(),
      plate: (j['immatriculation'] as String?) ?? '',
      odometerKm: (j['kilometrage'] as num?)?.toInt(),
      readings: [
        for (final r in (j['releves'] as List? ?? const []))
          OdometerReading.fromJson(Map<String, dynamic>.from(r as Map)),
      ],
      monthDone: month['saisi'] == true,
      month: month['mois'] is String ? DateTime.parse(month['mois'] as String) : null,
    );
  }

  final String id;
  final String name;
  final String plate;
  final int? odometerKm;

  /// Last 12 readings, newest first.
  final List<OdometerReading> readings;

  /// The reading of the current month is recorded.
  final bool monthDone;

  /// First day of the current month.
  final DateTime? month;

  String get label => '$name · $plate';

  OdometerReading? get last => readings.isEmpty ? null : readings.first;
}

class OdometerReading {
  const OdometerReading({required this.date, required this.odometerKm, this.toCheck = false, this.source});

  factory OdometerReading.fromJson(Map<String, dynamic> j) => OdometerReading(
        date: DateTime.parse(j['date'] as String),
        odometerKm: (j['kilometrage'] as num).toInt(),
        toCheck: j['aVerifier'] == true && j['corrige'] != true,
        source: j['source'] as String?,
      );

  final DateTime date;
  final int odometerKm;

  /// Flagged inconsistent by the database, waiting for the manager.
  final bool toCheck;
  final String? source;
}
