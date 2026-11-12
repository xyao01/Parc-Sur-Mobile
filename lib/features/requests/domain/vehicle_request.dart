import 'package:flutter/painting.dart';

import '../../../core/theme/parcsur_colors.dart';

/// Displayed state of a request. `terminee` and `enCours` are not stored: a validated request whose
/// return is past is « Terminée » (same rule as the web app); between departure and return it is « En cours ».
enum RequestState {
  attente('En attente', ParcColors.pendingBg, ParcColors.pendingText),
  validee('Validée', ParcColors.successBg, ParcColors.success),
  enCours('En cours', ParcColors.primarySoft, ParcColors.primary),
  terminee('Terminée', ParcColors.dividerSoft, ParcColors.textSecondary),
  refusee('Refusée', ParcColors.dangerSoft, ParcColors.danger),
  annulee('Annulée', ParcColors.dividerSoft, ParcColors.textMuted);

  const RequestState(this.label, this.bg, this.fg);

  final String label;
  final Color bg;
  final Color fg;
}

/// A row of `demande_vue` (requests of the signed-in requester).
class VehicleRequest {
  const VehicleRequest({
    required this.id,
    required this.number,
    required this.purpose,
    required this.destination,
    required this.departure,
    required this.plannedReturn,
    required this.passengers,
    required this.withDriver,
    required this.status,
    required this.createdAt,
    this.notes,
    this.vehicle,
    this.driver,
    this.refusalReason,
    this.cancellationReason,
    this.decidedAt,
  });

  factory VehicleRequest.fromJson(Map<String, dynamic> j) {
    DateTime? date(String k) => j[k] is String ? DateTime.parse(j[k] as String).toLocal() : null;
    String? text(String k) {
      final s = (j[k] as String?)?.trim();
      return s == null || s.isEmpty ? null : s;
    }

    return VehicleRequest(
      id: j['id'] as String,
      number: (j['numero'] as String?) ?? '',
      purpose: (j['motif'] as String?) ?? '',
      destination: (j['destination'] as String?) ?? '',
      departure: date('depart')!,
      plannedReturn: date('retour')!,
      passengers: (j['passagers'] as num?)?.toInt() ?? 1,
      withDriver: j['avec_chauffeur'] == true,
      notes: text('commentaire'),
      status: (j['statut'] as String?) ?? 'attente',
      vehicle: text('vehicule'),
      driver: text('chauffeur'),
      refusalReason: text('motif_refus'),
      cancellationReason: text('motif_annulation'),
      decidedAt: date('decide_le'),
      createdAt: date('created_at') ?? date('depart')!,
    );
  }

  final String id;

  /// `D-0142`
  final String number;
  final String purpose;
  final String destination;
  final DateTime departure;
  final DateTime plannedReturn;
  final int passengers;
  final bool withDriver;
  final String? notes;

  /// Stored status: `attente`, `validee`, `refusee`, `annulee`.
  final String status;

  /// `Toyota Prado · 3302 EA 01` once validated.
  final String? vehicle;
  final String? driver;
  final String? refusalReason;
  final String? cancellationReason;
  final DateTime? decidedAt;
  final DateTime createdAt;

  RequestState stateAt(DateTime now) => switch (status) {
        'validee' when !plannedReturn.isAfter(now) => RequestState.terminee,
        'validee' when !departure.isAfter(now) => RequestState.enCours,
        'validee' => RequestState.validee,
        'refusee' => RequestState.refusee,
        'annulee' => RequestState.annulee,
        _ => RequestState.attente,
      };

  /// Web rule (`actionsDemande`): the requester edits or cancels a pending request before departure.
  bool canEdit(DateTime now) => status == 'attente' && departure.isAfter(now);

  /// … and cancels a validated one before departure.
  bool canCancel(DateTime now) => (status == 'attente' || status == 'validee') && departure.isAfter(now);

  /// `Land Cruiser` from `Toyota Land Cruiser · 1150 FB 01`.
  String? get vehicleName => vehicle?.split(' · ').first;
}
