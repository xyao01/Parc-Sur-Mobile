import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/request_draft.dart';
import '../domain/vehicle_request.dart';
import 'requests_gateway.dart';
import 'supabase_requests_gateway.dart';

final requestsGatewayProvider = Provider<RequestsGateway>((ref) => SupabaseRequestsGateway(Supabase.instance.client));

/// Requests of the signed-in requester, newest first. Refresh with `ref.invalidate`.
final myRequestsProvider = FutureProvider.autoDispose<List<VehicleRequest>>((ref) async {
  final rows = await ref.watch(requestsGatewayProvider).myRequests();
  return [for (final r in rows) VehicleRequest.fromJson(r)]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final requestByIdProvider = Provider.autoDispose.family<AsyncValue<VehicleRequest?>, String>((ref, id) {
  return ref.watch(myRequestsProvider).whenData((list) {
    for (final r in list) {
      if (r.id == id) return r;
    }
    return null;
  });
});

/// Draft key of a new request (an edit uses the request id).
const newRequestDraftKey = 'nouvelle';

/// Entries of Mob-D02 kept for Mob-D03.
final requestDraftProvider = Provider.family<RequestDraft, String>((ref, key) => RequestDraft());
