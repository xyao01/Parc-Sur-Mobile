import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock.dart';
import '../../../core/french_dates.dart';
import '../../../core/offline/outbox.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/uuid.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../data/vehicle_gateway.dart';
import '../data/vehicle_providers.dart';
import '../domain/assigned_vehicle.dart';

const _months = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// Mob-D11 · Relevé mensuel (agent with an assigned vehicle, l2-km-02): `saisir_releve_mensuel`.
/// Kept on the phone without network and sent when it is back (l2-mob-04).
class MonthlyReadingScreen extends ConsumerWidget {
  const MonthlyReadingScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myVehiclesProvider);
    AssignedVehicle? vehicle;
    for (final v in async.value ?? const <AssignedVehicle>[]) {
      if (v.id == vehicleId) vehicle = v;
    }
    if (vehicle == null) {
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
                      const ParcErrorAlert(message: 'Ce véhicule ne vous est plus affecté.'),
                      const SizedBox(height: 12),
                      ParcOutlinedButton(
                        label: "Retour à l'accueil",
                        height: 46,
                        onPressed: () => context.go(Routes.requesterHome),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }
    return _Reading(vehicle: vehicle);
  }
}

enum _Done { no, sent, queued }

class _Reading extends ConsumerStatefulWidget {
  const _Reading({required this.vehicle});

  final AssignedVehicle vehicle;

  @override
  ConsumerState<_Reading> createState() => _ReadingState();
}

class _ReadingState extends ConsumerState<_Reading> {
  final _odometer = TextEditingController();
  final String _clientId = uuidV4();
  bool _busy = false;
  String? _error;
  _Done _done = _Done.no;
  String? _toCheck;

  @override
  void dispose() {
    _odometer.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.requesterHome);

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final km = parseKm(_odometer.text);
    if (km == null) {
      setState(() => _error = 'Indiquez le kilométrage au compteur.');
      return;
    }
    final reading = MonthlyReading(
      id: _clientId,
      vehicleId: widget.vehicle.id,
      odometerKm: km,
      date: ref.read(clockProvider)(),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await reading.sendWith(ref.read(vehicleGatewayProvider));
      ref.invalidate(myVehiclesProvider);
      if (mounted) {
        setState(() {
          _done = _Done.sent;
          _toCheck = r['aVerifier'] == true ? ((r['motif'] as String?) ?? '') : null;
        });
      }
    } on VehicleGatewayException catch (e) {
      if (!e.network) {
        if (mounted) setState(() => _error = e.message);
      } else {
        await ref.read(outboxProvider.notifier).add(OutboxItem(
              id: reading.id,
              kind: OutboxKind.monthlyReading,
              payload: reading.toJson(),
              createdAt: reading.date,
            ));
        if (mounted) setState(() => _done = _Done.queued);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Le relevé n’a pas pu être enregistré. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final now = ref.watch(clockProvider)();
    final month = '${_months[now.month - 1]} ${now.year}';
    final last = v.last;
    final km = parseKm(_odometer.text);
    Widget? hint;
    if (last != null) {
      final low = km != null && km < last.odometerKm;
      hint = KmHint(
        low
            ? 'Inférieur au dernier relevé (${FrenchDates.km(last.odometerKm)} km) : le gestionnaire le vérifiera.'
            : 'Dernier relevé : ${FrenchDates.km(last.odometerKm)} km le ${FrenchDates.dayMonth(last.date)}',
        ok: !low,
      );
    }
    return JourneyScaffold(
      offlineBanner: true,
      header: JourneyHeader(title: 'Relevé mensuel', subtitle: v.label, backLabel: "Retour à l'accueil", onBack: _back),
      bodyPadding: EdgeInsets.fromLTRB(20, _done == _Done.no ? 18 : 40, 20, 18),
      body: _done != _Done.no
          ? ResultView(
              icon: ParcIcons.checkBold,
              iconBg: ParcColors.successBg,
              iconColor: ParcColors.success,
              topPadding: 18,
              title: 'Relevé enregistré',
              message: Text(
                _done == _Done.queued
                    ? 'Enregistré sur le téléphone : il sera envoyé dès le retour du réseau.'
                    : _toCheck != null
                        ? 'Le gestionnaire vérifiera ce relevé${_toCheck!.isEmpty ? '' : ' : $_toCheck'}.'
                        : 'Merci : le kilométrage de $month est à jour.',
                textAlign: TextAlign.center,
                style: parcText(15, color: ParcColors.textSecondary, height: 1.5),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoNote('Relevé de $month demandé pour le véhicule qui vous est affecté.'),
                const SizedBox(height: 16),
                const FieldCaption('Kilométrage au compteur'),
                const SizedBox(height: 6),
                OdometerInput(
                  fieldKey: const Key('monthly.odometer'),
                  controller: _odometer,
                  onChanged: () => setState(() {}),
                  hint: hint,
                ),
                if (v.readings.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const SectionCaps('Derniers relevés'),
                  const SizedBox(height: 12),
                  WhiteCard(
                    radius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (final (i, r) in v.readings.take(6).indexed)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: i < v.readings.take(6).length - 1
                                  ? const Border(bottom: BorderSide(color: ParcColors.dividerSoft))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(FrenchDates.dayMonth(r.date), style: parcText(13, weight: 600, color: ParcColors.textMuted)),
                                ),
                                if (r.toCheck) ...[
                                  const StatusChip('À vérifier', bg: ParcColors.pendingBg, fg: ParcColors.pendingText),
                                  const SizedBox(width: 8),
                                ],
                                Text('${FrenchDates.km(r.odometerKm)} km', style: parcText(14, weight: 800)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (_error != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _error!)],
              ],
            ),
      footer: _done != _Done.no
          ? [ParcPrimaryButton(label: "Retour à l'accueil", onPressed: () => context.go(Routes.requesterHome))]
          : [JourneyActionButton(label: 'Enregistrer le relevé', busy: _busy, onPressed: _save)],
    );
  }
}
