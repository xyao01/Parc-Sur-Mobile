import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../features.dart';
import '../theme/parcsur_colors.dart';
import '../theme/parcsur_text.dart';
import 'parc_buttons.dart';
import 'parc_icon.dart';

/// « Page en maintenance »: shown instead of a view whose backend does not exist yet (see [Features]).
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key, this.feature});

  /// Name of the view, e.g. « Signaler un incident ».
  final String? feature;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    void back() => context.canPop() ? context.pop() : context.go(Routes.login);
    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: ParcColors.primary,
            padding: EdgeInsets.fromLTRB(20, 20 + top, 20, 18),
            child: Row(
              children: [
                ParcHeaderBackButton(
                  semanticLabel: 'Retour',
                  onPressed: back,
                  icon: const ParcIcon(ParcIcons.back, size: 20, color: ParcColors.surface),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      feature ?? 'ParcSûr',
                      style: parcText(18, weight: 800, color: ParcColors.surface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(color: ParcColors.pendingBg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const ParcIcon(ParcIcons.wrench, size: 46, color: ParcColors.pendingText),
                  ),
                  const SizedBox(height: 16),
                  Text('Page en maintenance', textAlign: TextAlign.center, style: parcText(24, weight: 800)),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      'Cette fonctionnalité n’est pas encore disponible. Revenez bientôt.',
                      textAlign: TextAlign.center,
                      style: parcText(15, color: ParcColors.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 22 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
              color: ParcColors.surface,
              border: Border(top: BorderSide(color: ParcColors.divider)),
            ),
            child: ParcPrimaryButton(label: 'Retour', onPressed: back),
          ),
        ],
      ),
    );
  }
}

/// Opens « Page en maintenance » for [feature].
void openMaintenance(BuildContext context, String feature) =>
    context.push(Uri(path: Routes.maintenance, queryParameters: {'vue': feature}).toString());

/// Shows [child] when [enabled] says its view is wired, « Page en maintenance » otherwise.
class FeatureGate extends ConsumerWidget {
  const FeatureGate({super.key, required this.enabled, required this.feature, required this.child});

  final bool Function(Features) enabled;
  final String feature;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      enabled(ref.watch(featuresProvider)) ? child : MaintenanceScreen(feature: feature);
}
