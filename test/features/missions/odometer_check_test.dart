import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/missions/domain/mission_flow_config.dart';
import 'package:parc_sur_mobile/features/missions/domain/odometer_check.dart';

/// Bug 19/11/2026: 452 753 026 850 km was shown « Cohérent avec le départ de la mission ».
/// Same rule as the database (seuil_km_par_jour(), 20261106110000_kilometrage_controle).
void main() {
  test('the ceiling is the database one: 1 500 km per day', () {
    expect(MissionFlowConfig.maxKmPerDay, 1500);
  });

  group('checkOdometer', () {
    final from = DateTime(2026, 11, 3, 7, 2);

    test('below the reference', () {
      expect(checkOdometer(km: 61479, reference: 61480, since: from, now: DateTime(2026, 11, 3, 9)), OdometerVerdict.low);
    });

    test('up to the ceiling on the same day', () {
      expect(checkOdometer(km: 61480, reference: 61480, since: from, now: DateTime(2026, 11, 3, 9)), OdometerVerdict.ok);
      expect(checkOdometer(km: 62980, reference: 61480, since: from, now: DateTime(2026, 11, 3, 9)), OdometerVerdict.ok);
    });

    test('beyond the ceiling', () {
      expect(checkOdometer(km: 62981, reference: 61480, since: from, now: DateTime(2026, 11, 3, 9)), OdometerVerdict.unusual);
      expect(checkOdometer(km: 452753026850, reference: 61480, since: from, now: DateTime(2026, 11, 3, 9)),
          OdometerVerdict.unusual);
    });

    test('the ceiling grows with each started day (as in the database)', () {
      // 2 days and 1 minute → 3 days → 4 500 km.
      final now = DateTime(2026, 11, 5, 7, 3);
      expect(checkOdometer(km: 61480 + 4500, reference: 61480, since: from, now: now), OdometerVerdict.ok);
      expect(checkOdometer(km: 61480 + 4501, reference: 61480, since: from, now: now), OdometerVerdict.unusual);
    });

    test('unknown date of the reference: one day', () {
      expect(checkOdometer(km: 61480 + 1501, reference: 61480, now: DateTime(2026, 11, 3, 9)), OdometerVerdict.unusual);
    });
  });
}
