import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../data/requests_providers.dart';
import '../domain/vehicle_request.dart';
import 'demandeur_nav.dart';
import 'request_widgets.dart';

/// Mob-D05 · Mes demandes (suivi), filtered by state.
class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  /// Tabs of the prototype; `null` = « Toutes ».
  static const _tabs = <(String, RequestState?)>[
    ('Toutes', null),
    ('En attente', RequestState.attente),
    ('Validées', RequestState.validee),
    ('En cours', RequestState.enCours),
    ('Terminées', RequestState.terminee),
  ];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final async = ref.watch(myRequestsProvider);
    final filter = _tabs[_tab].$2;
    final rows = (async.value ?? const <VehicleRequest>[])
        .where((r) => filter == null || r.stateAt(now) == filter)
        .toList();

    final List<Widget> content;
    if (async.isLoading && !async.hasValue) {
      content = const [SizedBox(height: 40), Center(child: CircularProgressIndicator(color: ParcColors.primary))];
    } else if (async.hasError && !async.hasValue) {
      content = [
        const ParcErrorAlert(message: 'Impossible de charger vos demandes.'),
        const SizedBox(height: 12),
        ParcOutlinedButton(label: 'Réessayer', height: 46, onPressed: () => ref.invalidate(myRequestsProvider)),
      ];
    } else if (rows.isEmpty) {
      content = [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Aucune demande dans cette catégorie.',
            textAlign: TextAlign.center,
            style: parcText(14, color: ParcColors.textMuted),
          ),
        ),
      ];
    } else {
      content = [
        for (final (i, r) in rows.indexed) ...[if (i > 0) const SizedBox(height: 10), _RequestRow(request: r, now: now)],
      ];
    }

    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        children: [
          JourneyHeader(
            title: 'Mes demandes',
            backLabel: "Retour à l'accueil",
            onBack: () => context.go(Routes.requesterHome),
            bottomPadding: 16,
            bottom: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, t) in _tabs.indexed) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _Tab(label: t.$1, selected: i == _tab, onTap: () => setState(() => _tab = i)),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: ParcColors.primary,
              onRefresh: () => ref.refresh(myRequestsProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: ParcPrimaryButton(
              label: 'Nouvelle demande',
              height: 52,
              fontSize: 15,
              leading: const ParcIcon(ParcIcons.plus, size: 18, color: ParcColors.surface),
              onPressed: () => context.push(Routes.newRequest),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const DemandeurBottomNav(currentIndex: 1),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? ParcColors.surface : ParcColors.headerChip,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(label, style: parcText(14, weight: 800, color: selected ? ParcColors.primary : ParcColors.surface)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.now});

  final VehicleRequest request;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final state = r.stateAt(now);
    return Material(
      color: ParcColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ParcColors.divider),
      ),
      child: InkWell(
        onTap: () => context.push(routeForRequest(r, now)),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(r.destination, style: parcText(16, weight: 800), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text(r.number, style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(FrenchDates.dayRange(r.departure, r.plannedReturn), style: parcText(13, color: ParcColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusChip(state.label, bg: state.bg, fg: state.fg),
            ],
          ),
        ),
      ),
    );
  }
}
