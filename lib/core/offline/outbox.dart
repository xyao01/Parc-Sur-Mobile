import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_store.dart';

/// Kinds of entries kept while offline (l2-mob-04).
abstract final class OutboxKind {
  /// `enregistrer_controle` (departure / return check).
  static const control = 'controle';

  /// `saisir_releve_mensuel` (monthly odometer of an agent's vehicle).
  static const monthlyReading = 'releve_mensuel';

  /// `saisir_plein_chauffeur` (fill-up during the mission, with its ticket photos).
  static const fuel = 'plein';

  /// `signaler_incident_chauffeur` (incident during the mission, with its photos).
  static const incident = 'incident';
}

/// An entry not sent yet. [id] is the client id sent to the server, which ignores a second copy.
class OutboxItem {
  const OutboxItem({required this.id, required this.kind, required this.payload, required this.createdAt});

  factory OutboxItem.fromJson(Map<String, dynamic> j) => OutboxItem(
        id: j['id'] as String,
        kind: j['kind'] as String,
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  final String id;
  final String kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'payload': payload, 'createdAt': createdAt.toIso8601String()};
}

/// Entry refused by the server when it was finally sent (shown to the user, kept until dismissed).
class RejectedEntry {
  const RejectedEntry({required this.item, required this.message});

  factory RejectedEntry.fromJson(Map<String, dynamic> j) =>
      RejectedEntry(item: OutboxItem.fromJson(Map<String, dynamic>.from(j['item'] as Map)), message: j['message'] as String);

  final OutboxItem item;
  final String message;

  Map<String, dynamic> toJson() => {'item': item.toJson(), 'message': message};
}

class OutboxState {
  const OutboxState({this.pending = const [], this.rejected = const []});

  final List<OutboxItem> pending;
  final List<RejectedEntry> rejected;
}

/// Entries waiting for the network, saved on the phone after every change.
final outboxProvider = NotifierProvider<OutboxNotifier, OutboxState>(OutboxNotifier.new);

class OutboxNotifier extends Notifier<OutboxState> {
  static const _pendingKey = 'outbox.pending.v1';
  static const _rejectedKey = 'outbox.rejected.v1';

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  OutboxState build() {
    final store = ref.watch(localStoreProvider);
    List<T> load<T>(String key, T Function(Map<String, dynamic>) from) {
      final raw = store.read(key);
      if (raw == null) return const [];
      try {
        return [for (final e in jsonDecode(raw) as List) from(Map<String, dynamic>.from(e as Map))];
      } catch (_) {
        return const [];
      }
    }

    return OutboxState(pending: load(_pendingKey, OutboxItem.fromJson), rejected: load(_rejectedKey, RejectedEntry.fromJson));
  }

  Future<void> _save(OutboxState next) async {
    state = next;
    await _store.write(_pendingKey, jsonEncode([for (final i in next.pending) i.toJson()]));
    await _store.write(_rejectedKey, jsonEncode([for (final r in next.rejected) r.toJson()]));
  }

  Future<void> add(OutboxItem item) => _save(OutboxState(
        pending: [...state.pending.where((i) => i.id != item.id), item],
        rejected: state.rejected,
      ));

  Future<void> sent(String id) =>
      _save(OutboxState(pending: [for (final i in state.pending) if (i.id != id) i], rejected: state.rejected));

  Future<void> reject(OutboxItem item, String message) => _save(OutboxState(
        pending: [for (final i in state.pending) if (i.id != item.id) i],
        rejected: [...state.rejected, RejectedEntry(item: item, message: message)],
      ));

  Future<void> dismissRejected() => _save(OutboxState(pending: state.pending));
}
