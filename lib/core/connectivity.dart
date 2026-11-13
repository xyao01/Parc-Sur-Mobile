import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network reachable (Wi-Fi, mobile data, Ethernet…), from the operating system.
/// Overridden in tests. A request can still fail while « online »: the sync handles it.
final onlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool up(List<ConnectivityResult> r) => r.any((c) => c != ConnectivityResult.none);
  yield up(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(up);
});

/// Whether the device is offline. Drives the « Hors connexion » banner.
final isOfflineProvider = Provider<bool>((ref) => ref.watch(onlineProvider).value == false);
