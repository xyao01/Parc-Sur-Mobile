import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../data/missions_providers.dart';
import '../domain/mission.dart';

/// Resolves a mission (or pending request) by id for the journey screens:
/// spinner while loading, message when it is no longer assigned.
class MissionLoader extends ConsumerWidget {
  const MissionLoader({super.key, required this.missionId, required this.builder});

  final String missionId;
  final Widget Function(BuildContext context, Mission mission) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(missionByIdProvider(missionId));
    final mission = async.value;
    if (mission != null) return builder(context, mission);
    return Scaffold(
      backgroundColor: ParcColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: async.isLoading
              ? const Center(child: CircularProgressIndicator(color: ParcColors.primary))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ParcErrorAlert(
                      message: async.hasError
                          ? 'Impossible de charger la mission.'
                          : 'Cette mission ne vous est plus attribuée.',
                    ),
                    const SizedBox(height: 12),
                    ParcOutlinedButton(label: "Retour à l'accueil", height: 46, onPressed: () => context.go(Routes.missions)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Back navigation of the journey: previous screen, or the driver home.
void journeyBack(BuildContext context) => context.canPop() ? context.pop() : context.go(Routes.missions);
