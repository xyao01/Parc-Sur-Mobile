import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../data/requests_gateway.dart';
import '../data/requests_providers.dart';
import '../domain/request_config.dart';
import '../domain/vehicle_request.dart';
import 'request_widgets.dart';

/// Mob-D10 · Évaluation et clôture. Sent through `RequestsGateway.rate` (no backend yet: see README).
class RequestRatingScreen extends StatelessWidget {
  const RequestRatingScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) =>
      RequestLoader(requestId: requestId, builder: (context, r, now) => _Rating(request: r));
}

class _Rating extends ConsumerStatefulWidget {
  const _Rating({required this.request});

  final VehicleRequest request;

  @override
  ConsumerState<_Rating> createState() => _RatingState();
}

class _RatingState extends ConsumerState<_Rating> {
  int _rating = 0;
  final Set<String> _tags = {};
  final _comment = TextEditingController();
  bool _showError = false;
  bool _busy = false;
  bool _done = false;
  String? _failure;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_rating == 0) {
      setState(() => _showError = true);
      return;
    }
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(requestsGatewayProvider).rate(
            requestId: widget.request.id,
            rating: _rating,
            tags: [for (final t in RequestConfig.ratingTags) if (_tags.contains(t)) t],
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          );
      if (mounted) setState(() => _done = true);
    } on RequestsGatewayException catch (e) {
      if (mounted) setState(() => _failure = e.message);
    } catch (_) {
      if (mounted) setState(() => _failure = 'L’évaluation n’a pas pu être envoyée. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return JourneyScaffold(
      header: JourneyHeader(
        title: 'Évaluation et clôture',
        subtitle: r.number,
        onBack: () => requestBack(context, Routes.myRequests),
      ),
      bodyPadding: EdgeInsets.fromLTRB(20, _done ? 40 : 20, 20, 20),
      body: _done
          ? ResultView(
              icon: ParcIcons.checkBold,
              iconBg: ParcColors.successBg,
              iconColor: ParcColors.success,
              circle: 96,
              iconSize: 50,
              titleSize: 26,
              topPadding: 18,
              title: 'Demande clôturée',
              message: Text(
                'Merci pour votre retour. La demande ${r.number} est terminée et conservée dans votre historique.',
                textAlign: TextAlign.center,
                style: parcText(15, color: ParcColors.textSecondary, height: 1.5),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(header: true, child: Text("Comment s'est passée la mission ?", style: parcText(20, weight: 800))),
                const SizedBox(height: 4),
                Text(
                  [r.destination, if (r.driver != null) 'chauffeur ${r.driver}'].join(' · '),
                  style: parcText(14, color: ParcColors.textMuted),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (var n = 1; n <= 5; n++) ...[
                      if (n > 1) const SizedBox(width: 6),
                      Expanded(child: _Star(value: n, on: _rating >= n, selected: _rating == n, onTap: () => setState(() {
                        _rating = n;
                        _showError = false;
                      }))),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Insatisfaisant', style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                    Text('Excellent', style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in RequestConfig.ratingTags)
                      PillChoice(
                        label: t,
                        selected: _tags.contains(t),
                        onTap: () => setState(() => _tags.contains(t) ? _tags.remove(t) : _tags.add(t)),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const FieldCaption('Commentaire', suffix: '(facultatif)'),
                const SizedBox(height: 6),
                ParcTextField(
                  controller: _comment,
                  height: null,
                  maxLines: 3,
                  fontSize: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  hintText: 'Votre remarque sur le véhicule, le chauffeur ou le trajet…',
                ),
                if (_failure != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _failure!)],
              ],
            ),
      footer: _done
          ? [
              ParcPrimaryButton(label: "Retour à l'accueil", onPressed: () => context.go(Routes.requesterHome)),
              ParcOutlinedButton(label: 'Faire une nouvelle demande', height: 48, onPressed: () => context.push(Routes.newRequest)),
            ]
          : [
              if (_showError && _rating == 0)
                Center(child: FieldError('Donnez une note de 1 à 5 pour clôturer.')),
              JourneyActionButton(label: 'Envoyer et clôturer la demande', ready: _rating > 0, busy: _busy, onPressed: _send),
            ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.value, required this.on, required this.selected, required this.onTap});

  final int value;
  final bool on;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '$value sur 5',
      excludeSemantics: true,
      child: Material(
        color: on ? ParcColors.pendingBg : ParcColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: on ? ParcColors.accent : ParcColors.inputBorder, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 56,
            child: Center(child: ParcIcon(on ? ParcIcons.starOn : ParcIcons.starOff, size: 28, color: ParcColors.accent)),
          ),
        ),
      ),
    );
  }
}
