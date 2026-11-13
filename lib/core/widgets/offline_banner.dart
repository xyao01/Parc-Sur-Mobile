import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity.dart';
import '../offline/outbox.dart';
import '../theme/parcsur_colors.dart';
import '../theme/parcsur_text.dart';
import 'parc_icon.dart';

/// Sync state of the entries kept on the phone (l2-mob-04), under a header:
/// offline (prototype « Mobile · Contrôle de départ »), entries waiting, or refused by the server.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    final outbox = ref.watch(outboxProvider);
    final pending = outbox.pending.length;
    final rejected = outbox.rejected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (offline)
          const _Line(icon: ParcIcons.wifiOff, text: 'Hors connexion : la saisie sera envoyée dès le retour du réseau.')
        else if (pending > 0)
          _Line(icon: ParcIcons.clock, text: '$pending saisie${pending > 1 ? 's' : ''} en attente d’envoi.'),
        if (rejected.isNotEmpty)
          Semantics(
            liveRegion: true,
            child: Container(
              color: ParcColors.dangerSoft,
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  const ParcIcon(ParcIcons.warning, size: 16, color: ParcColors.dangerStrong),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${rejected.length} saisie${rejected.length > 1 ? 's' : ''} refusée${rejected.length > 1 ? 's' : ''} '
                      'par le serveur : ${rejected.last.message}',
                      style: parcText(12, weight: 600, color: ParcColors.dangerStrong),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(outboxProvider.notifier).dismissRejected(),
                    child: Text('OK', style: parcText(13, weight: 800, color: ParcColors.dangerStrong)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        color: ParcColors.warningBg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            ParcIcon(icon, size: 16, color: ParcColors.warningText),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: parcText(12, weight: 600, color: ParcColors.warningText))),
          ],
        ),
      ),
    );
  }
}
