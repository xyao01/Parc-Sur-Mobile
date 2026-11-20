import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Views of the prototypes that have no backend yet. While a flag is off, the view opens
/// « Page en maintenance » instead (decision of 12/11/2026). Turn a flag on once its Supabase call exists.
class Features {
  const Features({
    this.driverRequestAnswer = false,
    this.driverAvailability = true,
    this.availabilityCard = false,
    this.driverIncident = true,
    this.blockDeparture = false,
    this.photos = false,
    this.phoneCalls = false,
    this.requesterProblem = false,
    this.missionRating = false,
    this.driverRecordReport = false,
    this.missionExpenses = false,
    this.fuelEntry = true,
  });

  /// Every view enabled (tests of the screens themselves).
  const Features.all()
      : driverRequestAnswer = true,
        driverAvailability = true,
        availabilityCard = true,
        driverIncident = true,
        blockDeparture = true,
        photos = true,
        phoneCalls = true,
        requesterProblem = true,
        missionRating = true,
        driverRecordReport = true,
        missionExpenses = true,
        fuelEntry = true;

  /// Mob-C02…C04: answer to a request (no answer step in the database).
  final bool driverRequestAnswer;

  /// Mob-C01 « Je suis disponible » (`ma_disponibilite`, `declarer_indisponible`, `declarer_disponible`, 20261116110000_disponibilite_chauffeur).
  final bool driverAvailability;

  /// Mob-C01: the « Je suis disponible » row is shown on the driver home. Hidden (request of 20/11/2026).
  final bool availabilityCard;

  /// Mob-C07 « Signaler un incident » (`signaler_incident_chauffeur`, 20261116130000_incident_chauffeur).
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

  /// Profile: driver's « Signaler une erreur à mon gestionnaire » (no reporting call yet).
  final bool driverRecordReport;

  /// Mob-C10 « Dépenses engagées » (l2-mis-02): table depense closed to drivers.
  final bool missionExpenses;

  /// Mob-C13 « Ajouter un plein » (`saisir_plein_chauffeur`, 20261116100000_plein_chauffeur).
  final bool fuelEntry;
}

final featuresProvider = Provider<Features>((ref) => const Features());
