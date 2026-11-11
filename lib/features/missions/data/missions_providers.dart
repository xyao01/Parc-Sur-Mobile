import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../domain/mission.dart';

/// Signed-in driver. Demo value until authentication is wired.
final currentDriverProvider = Provider<Driver>((ref) => const Driver(firstName: 'Yao', lastName: 'Kouadio'));

/// Driver missions, sorted by departure.
///
/// Demo data taken from the prototype, positioned relative to the clock so the
/// « Mission du jour » is always today. Replace with the Supabase repository.
final missionsProvider = Provider<List<Mission>>((ref) {
  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int dayOffset, int h, [int m = 0]) => today.add(Duration(days: dayOffset, hours: h, minutes: m));

  final landCruiser = Vehicle(
    model: 'Land Cruiser',
    plate: '1150 FB 01',
    lastOdometer: OdometerReading(km: 84112, date: today.subtract(const Duration(days: 4))),
  );
  return [
    Mission(
      id: 'D-0139',
      origin: 'Abidjan',
      destination: 'Yamoussoukro',
      vehicle: landCruiser,
      departure: at(0, 7, 30),
      plannedReturn: at(1, 17),
      requester: 'Koffi Ouattara',
      passengers: 2,
    ),
    Mission(
      id: 'D-0144',
      origin: 'Abidjan',
      destination: 'Abengourou',
      vehicle: const Vehicle(model: 'Toyota Prado', plate: '2087 FC 01'),
      departure: at(3, 6),
      plannedReturn: at(4, 18),
      requester: 'Aya Konan',
      passengers: 1,
    ),
    Mission(
      id: 'D-0151',
      origin: 'Abidjan',
      destination: 'Korhogo',
      vehicle: null,
      departure: at(7, 6),
      plannedReturn: at(10, 17),
      requester: 'Koffi Ouattara',
      passengers: 3,
    ),
  ];
});

final missionByIdProvider = Provider.family<Mission?, String>((ref, id) {
  for (final m in ref.watch(missionsProvider)) {
    if (m.id == id) return m;
  }
  return null;
});
