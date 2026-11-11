import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device is offline. Drives the « Hors connexion » banner.
///
/// Not yet wired to a connectivity source: always `false` until the offline
/// sync strategy is decided (see README, « Points ouverts »).
final isOfflineProvider = Provider<bool>((ref) => false);
