import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/connectivity.dart';
import '../core/offline/outbox.dart';
import '../features/missions/data/control_submitter.dart';
import '../features/missions/data/fuel_submitter.dart';
import '../features/missions/data/missions_gateway.dart';
import '../features/missions/data/missions_providers.dart';
import '../features/missions/data/ticket_camera.dart';
import '../features/vehicle/data/vehicle_gateway.dart';
import '../features/vehicle/data/vehicle_providers.dart';

/// Sends the entries kept on the phone (l2-mob-04): at start, and each time the network comes back.
/// Stops at the first network failure (order kept); a business refusal is moved to « rejected ».
/// State: a send is in progress.
final syncProvider = NotifierProvider<SyncNotifier, bool>(SyncNotifier.new);

class SyncNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(onlineProvider, (_, next) {
      if (next.value == true) flush();
    });
    Future.microtask(flush);
    return false;
  }

  Future<void> flush() async {
    if (state) return;
    final items = ref.read(outboxProvider).pending;
    if (items.isEmpty) return;
    state = true;
    final outbox = ref.read(outboxProvider.notifier);
    var sentAny = false;
    try {
      for (final item in items) {
        try {
          await _send(item);
          await outbox.sent(item.id);
          sentAny = true;
        } on MissionsGatewayException catch (e) {
          if (e.network) break;
          await outbox.reject(item, e.message);
        } on VehicleGatewayException catch (e) {
          if (e.network) break;
          await outbox.reject(item, e.message);
        }
      }
    } finally {
      state = false;
    }
    if (sentAny) {
      ref.invalidate(missionsProvider);
      ref.invalidate(myVehiclesProvider);
    }
  }

  Future<void> _send(OutboxItem item) => switch (item.kind) {
        OutboxKind.control => ControlEntry.fromJson(item.id, item.payload).sendWith(ref.read(missionsGatewayProvider)),
        OutboxKind.monthlyReading => MonthlyReading.fromJson(item.id, item.payload).sendWith(ref.read(vehicleGatewayProvider)),
        OutboxKind.fuel => _sendFuel(FuelEntry.fromJson(item.id, item.payload)),
        _ => Future.value(),
      };

  Future<void> _sendFuel(FuelEntry entry) async {
    await entry.sendWith(ref.read(missionsGatewayProvider));
    await ref.read(ticketCameraProvider).discard(entry.tickets);
  }
}
