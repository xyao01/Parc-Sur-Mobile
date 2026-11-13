import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/outbox.dart';
import 'missions_gateway.dart';
import 'missions_providers.dart';

/// A departure / return check (`enregistrer_controle`).
class ControlEntry {
  const ControlEntry({
    required this.id,
    required this.missionId,
    required this.type,
    required this.odometerKm,
    required this.fuel,
    required this.points,
    required this.enteredAt,
    this.observations,
  });

  factory ControlEntry.fromJson(String id, Map<String, dynamic> j) => ControlEntry(
        id: id,
        missionId: j['missionId'] as String,
        type: j['type'] as String,
        odometerKm: (j['km'] as num).toInt(),
        fuel: j['fuel'] as String,
        points: Map<String, String>.from(j['points'] as Map),
        observations: j['observations'] as String?,
        enteredAt: DateTime.parse(j['enteredAt'] as String),
      );

  /// Client id: a second copy of the same check is ignored by the server.
  final String id;
  final String missionId;

  /// `depart` or `retour`.
  final String type;
  final int odometerKm;
  final String fuel;
  final Map<String, String> points;
  final String? observations;

  /// Time of the entry on the phone (sent as `p_saisi_le`, even when sent later).
  final DateTime enteredAt;

  Map<String, dynamic> toJson() => {
        'missionId': missionId,
        'type': type,
        'km': odometerKm,
        'fuel': fuel,
        'points': points,
        'observations': observations,
        'enteredAt': enteredAt.toIso8601String(),
      };

  Future<void> sendWith(MissionsGateway gateway) => gateway.recordControl(
        id: id,
        missionId: missionId,
        type: type,
        odometerKm: odometerKm,
        fuel: fuel,
        points: points,
        observations: observations,
        enteredAt: enteredAt,
      );
}

enum SubmitResult { sent, queued }

/// Sends a check now, or keeps it on the phone when the network is missing (l2-mob-04).
/// Business refusals of the server are thrown as [MissionsGatewayException].
final controlSubmitterProvider = Provider<ControlSubmitter>(ControlSubmitter.new);

class ControlSubmitter {
  ControlSubmitter(this._ref);

  final Ref _ref;

  Future<SubmitResult> submit(ControlEntry entry) async {
    try {
      await entry.sendWith(_ref.read(missionsGatewayProvider));
      return SubmitResult.sent;
    } on MissionsGatewayException catch (e) {
      if (!e.network) rethrow;
      await _ref.read(outboxProvider.notifier).add(OutboxItem(
            id: entry.id,
            kind: OutboxKind.control,
            payload: entry.toJson(),
            createdAt: entry.enteredAt,
          ));
      return SubmitResult.queued;
    }
  }
}
