import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Views of the prototypes that have no backend yet. While a flag is off, the view opens
/// « Page en maintenance » instead (decision of 12/11/2026). Turn a flag on once its Supabase call exists.
class Features {
  const Features({
    this.driverRequestAnswer = false,
    this.driverAvailability = false,
    this.driverIncident = false,
    this.blockDeparture = false,
    this.photos = false,
    this.phoneCalls = false,
    this.requesterProblem = false,
    this.missionRating = false,
    this.driverAccountDetails = false,
    this.missionExpenses = false,
  });

  /// Every view enabled (tests of the screens themselves).
  const Features.all()
      : driverRequestAnswer = true,
        driverAvailability = true,
        driverIncident = true,
        blockDeparture = true,
        photos = true,
        phoneCalls = true,
        requesterProblem = true,
        missionRating = true,
        driverAccountDetails = true,
        missionExpenses = true;

  /// Mob-C02…C04: answer to a request (no answer step in the database).
  final bool driverRequestAnswer;

  /// Mob-C01 « Je suis disponible ».
  final bool driverAvailability;

  /// Mob-C07 « Signaler un incident ».
  final bool driverIncident;

  /// Mob-C06 « Un problème : bloquer le départ ».
  final bool blockDeparture;

  /// Photo capture (C05, C06, C09).
  final bool photos;

  /// Phone call buttons (requester, driver).
  final bool phoneCalls;

  /// Mob-D08 « Signaler un problème ».
  final bool requesterProblem;

  /// Mob-D10 evaluation.
  final bool missionRating;

  /// Profile: driver's phone and licence (table chauffeur not readable by drivers).
  final bool driverAccountDetails;

  /// Mob-C10 « Dépenses engagées » (l2-mis-02): table depense closed to drivers.
  final bool missionExpenses;
}

final featuresProvider = Provider<Features>((ref) => const Features());
