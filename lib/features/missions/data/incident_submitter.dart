import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/outbox.dart';
import 'control_submitter.dart';
import 'missions_gateway.dart';
import 'missions_providers.dart';
import 'ticket_camera.dart';

/// An incident reported by the driver during the mission (Mob-C07, `signaler_incident_chauffeur`).
class IncidentEntry {
  const IncidentEntry({
    required this.id,
    required this.missionId,
    required this.kind,
    required this.serious,
    required this.photos,
    required this.enteredAt,
    this.description,
  });

  factory IncidentEntry.fromJson(String id, Map<String, dynamic> j) => IncidentEntry(
        id: id,
        missionId: j['missionId'] as String,
        kind: j['kind'] as String,
        description: j['description'] as String?,
        serious: j['serious'] as bool,
        photos: [for (final p in j['photos'] as List) p as String],
        enteredAt: DateTime.parse(j['enteredAt'] as String),
      );

  /// Client id, also the folder of the photos: a resend is neither counted nor stored twice.
  final String id;
  final String missionId;

  /// One of `MissionFlowConfig.incidentKinds`.
  final String kind;
  final String? description;

  /// « Incident grave » ticked: the vehicle is immobilised and the mission interrupted.
  final bool serious;

  /// Photos on the phone (0 to 2).
  final List<String> photos;
  final DateTime enteredAt;

  /// Where photo [i] goes in the `justificatifs` storage.
  String remotePhoto(int i) => 'sinistres/$id/${i + 1}-photo.jpg';

  Map<String, dynamic> toJson() => {
        'missionId': missionId,
        'kind': kind,
        'description': description,
        'serious': serious,
        'photos': photos,
        'enteredAt': enteredAt.toIso8601String(),
      };

  /// Photos first, then the incident that refers to them.
  Future<void> sendWith(MissionsGateway gateway) async {
    for (final (i, p) in photos.indexed) {
      await gateway.uploadTicket(localPath: p, remotePath: remotePhoto(i));
    }
    await gateway.reportMissionIncident(
      id: id,
      missionId: missionId,
      kind: kind,
      description: description,
      serious: serious,
      photos: [for (var i = 0; i < photos.length; i++) remotePhoto(i)],
      enteredAt: enteredAt,
    );
  }
}

/// Sends an incident now, or keeps it on the phone with its photos when the network is missing.
final incidentSubmitterProvider = Provider<IncidentSubmitter>(IncidentSubmitter.new);

class IncidentSubmitter {
  IncidentSubmitter(this._ref);

  final Ref _ref;

  Future<SubmitResult> submit(IncidentEntry entry) async {
    try {
      await entry.sendWith(_ref.read(missionsGatewayProvider));
      await _ref.read(ticketCameraProvider).discard(entry.photos);
      return SubmitResult.sent;
    } on MissionsGatewayException catch (e) {
      if (!e.network) rethrow;
      await _ref
          .read(outboxProvider.notifier)
          .add(OutboxItem(id: entry.id, kind: OutboxKind.incident, payload: entry.toJson(), createdAt: entry.enteredAt));
      return SubmitResult.queued;
    }
  }
}
