import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/outbox.dart';
import 'control_submitter.dart';
import 'missions_gateway.dart';
import 'missions_providers.dart';
import 'ticket_camera.dart';

/// A fill-up entered by the driver during the mission (Mob-C13, `saisir_plein_chauffeur`).
class FuelEntry {
  const FuelEntry({
    required this.id,
    required this.missionId,
    required this.odometerKm,
    required this.litres,
    required this.amount,
    required this.full,
    required this.tickets,
    required this.enteredAt,
    this.station,
  });

  factory FuelEntry.fromJson(String id, Map<String, dynamic> j) => FuelEntry(
    id: id,
    missionId: j['missionId'] as String,
    odometerKm: (j['km'] as num).toInt(),
    litres: (j['litres'] as num).toDouble(),
    amount: (j['amount'] as num).toInt(),
    full: j['full'] as bool,
    station: j['station'] as String?,
    tickets: [for (final t in j['tickets'] as List) t as String],
    enteredAt: DateTime.parse(j['enteredAt'] as String),
  );

  /// Client id, also the folder of the tickets: a resend is neither counted nor stored twice.
  final String id;
  final String missionId;
  final int odometerKm;
  final double litres;

  /// FCFA.
  final int amount;
  final bool full;
  final String? station;

  /// Photos on the phone (1 or 2).
  final List<String> tickets;
  final DateTime enteredAt;

  /// Where ticket [i] goes in the `justificatifs` storage.
  String remoteTicket(int i) => 'carburant/$id/${i + 1}-ticket.jpg';

  Map<String, dynamic> toJson() => {
    'missionId': missionId,
    'km': odometerKm,
    'litres': litres,
    'amount': amount,
    'full': full,
    'station': station,
    'tickets': tickets,
    'enteredAt': enteredAt.toIso8601String(),
  };

  /// Tickets first, then the fill-up that refers to them.
  Future<void> sendWith(MissionsGateway gateway) async {
    for (final (i, t) in tickets.indexed) {
      await gateway.uploadTicket(localPath: t, remotePath: remoteTicket(i));
    }
    await gateway.recordFuel(
      id: id,
      missionId: missionId,
      odometerKm: odometerKm,
      litres: litres,
      amount: amount,
      full: full,
      station: station,
      tickets: [for (var i = 0; i < tickets.length; i++) remoteTicket(i)],
      enteredAt: enteredAt,
    );
  }
}

/// Sends a fill-up now, or keeps it on the phone with its tickets when the network is missing.
final fuelSubmitterProvider = Provider<FuelSubmitter>(FuelSubmitter.new);

class FuelSubmitter {
  FuelSubmitter(this._ref);

  final Ref _ref;

  Future<SubmitResult> submit(FuelEntry entry) async {
    try {
      await entry.sendWith(_ref.read(missionsGatewayProvider));
      await _ref.read(ticketCameraProvider).discard(entry.tickets);
      return SubmitResult.sent;
    } on MissionsGatewayException catch (e) {
      if (!e.network) rethrow;
      await _ref
          .read(outboxProvider.notifier)
          .add(OutboxItem(id: entry.id, kind: OutboxKind.fuel, payload: entry.toJson(), createdAt: entry.enteredAt));
      return SubmitResult.queued;
    }
  }
}
