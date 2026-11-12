import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../missions/presentation/journey_widgets.dart';
import 'request_widgets.dart';

/// Mob-D04 · Demande envoyée.
class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return RequestLoader(
      requestId: requestId,
      builder: (context, r, now) {
        final top = MediaQuery.paddingOf(context).top;
        return JourneyScaffold(
          header: Container(
            width: double.infinity,
            color: ParcColors.primary,
            padding: EdgeInsets.fromLTRB(20, 20 + top, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stepLabel(4), style: parcText(12, weight: 600, color: ParcColors.onPrimaryMuted)),
                Semantics(header: true, child: Text('Demande envoyée', style: parcText(18, weight: 800, color: ParcColors.surface))),
              ],
            ),
          ),
          bodyPadding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResultView(
                icon: ParcIcons.checkBold,
                iconBg: ParcColors.successBg,
                iconColor: ParcColors.success,
                circle: 96,
                iconSize: 50,
                topPadding: 18,
                title: 'Votre demande est envoyée',
                message: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Référence '),
                    TextSpan(text: r.number, style: parcText(15, weight: 800, color: ParcColors.textSecondary, height: 1.5)),
                    TextSpan(text: ' · ${r.destination}. Un administrateur va l\'examiner.'),
                  ]),
                  textAlign: TextAlign.center,
                  style: parcText(15, color: ParcColors.textSecondary, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              RequestTimeline(request: r, now: now, reviewInProgressLabel: true),
            ],
          ),
          footer: [
            ParcPrimaryButton(label: 'Suivre mes demandes', onPressed: () => context.go(Routes.myRequests)),
            ParcOutlinedButton(label: "Retour à l'accueil", height: 48, onPressed: () => context.go(Routes.requesterHome)),
          ],
        );
      },
    );
  }
}
