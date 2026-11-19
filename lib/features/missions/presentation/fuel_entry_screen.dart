import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/uuid.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../data/control_submitter.dart';
import '../data/fuel_submitter.dart';
import '../data/missions_gateway.dart';
import '../data/ticket_camera.dart';
import '../domain/mission.dart';
import '../domain/odometer_check.dart';
import 'journey_widgets.dart';
import 'mission_loader.dart';

/// Mob-C13 · Ajouter un plein, during the mission only (decisions of 16/11/2026):
/// ticket photo required, counted at once, kept on the phone without network.
class FuelEntryScreen extends StatelessWidget {
  const FuelEntryScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context) => MissionLoader(
    missionId: missionId,
    builder: (context, m) => _FuelEntry(mission: m),
  );
}

/// At most 2 receipts per fill-up (`verifier_justificatifs`).
const maxTickets = 2;

/// `48,5` → 48.5 (comma or dot).
double? parseLitres(String text) {
  final v = double.tryParse(text.trim().replaceAll(RegExp(r'\s'), '').replaceAll(',', '.'));
  return v == null || v <= 0 ? null : v;
}

/// `48.5` → `48,5`.
String formatLitres(double v) =>
    (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')).replaceAll(
      '.',
      ',',
    );

class _FuelEntry extends ConsumerStatefulWidget {
  const _FuelEntry({required this.mission});

  final Mission mission;

  @override
  ConsumerState<_FuelEntry> createState() => _FuelEntryState();
}

class _FuelEntryState extends ConsumerState<_FuelEntry> {
  final String _clientId = uuidV4();
  final _odometer = TextEditingController();
  final _litres = TextEditingController();
  final _amount = TextEditingController();
  final _station = TextEditingController();
  final _tickets = <String>[];
  bool _full = true;
  bool _busy = false;
  bool _ticketMissing = false;
  String? _error;
  SubmitResult? _done;
  FuelEntry? _saved;

  @override
  void dispose() {
    _odometer.dispose();
    _litres.dispose();
    _amount.dispose();
    _station.dispose();
    super.dispose();
  }

  int? get _departureKm => widget.mission.departureCheck?.odometerKm;

  void _back() => context.canPop() ? context.pop() : context.go(Routes.inProgress(widget.mission.id));

  Future<void> _takeTicket() async {
    final path = await ref.read(ticketCameraProvider).take();
    if (path == null || !mounted) return;
    setState(() {
      _tickets.add(path);
      _ticketMissing = false;
    });
  }

  String? _check(int? km, double? litres, int? amount) {
    final departure = _departureKm;
    if (km == null) return 'Indiquez le kilométrage au compteur.';
    if (departure != null && km < departure) {
      return 'Le kilométrage ne peut pas être inférieur au départ de la mission (${FrenchDates.km(departure)} km).';
    }
    if (litres == null) return 'Indiquez le nombre de litres.';
    if (amount == null || amount <= 0) return 'Indiquez le montant payé.';
    return null;
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final km = parseKm(_odometer.text);
    final litres = parseLitres(_litres.text);
    final amount = parseKm(_amount.text);
    final error = _check(km, litres, amount);
    setState(() {
      _error = error;
      _ticketMissing = _tickets.isEmpty;
    });
    if (error != null || _tickets.isEmpty) return;

    final station = _station.text.trim();
    final entry = FuelEntry(
      id: _clientId,
      missionId: widget.mission.id,
      odometerKm: km!,
      litres: litres!,
      amount: amount!,
      full: _full,
      station: station.isEmpty ? null : station,
      tickets: List.of(_tickets),
      enteredAt: ref.read(clockProvider)(),
    );
    setState(() => _busy = true);
    try {
      final result = await ref.read(fuelSubmitterProvider).submit(entry);
      if (mounted) {
        setState(() {
          _done = result;
          _saved = entry;
        });
      }
    } on MissionsGatewayException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Le plein n’a pas pu être enregistré. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final header = JourneyHeader(
      title: 'Ajouter un plein',
      subtitle: '${m.number} · ${m.vehicle.label}',
      backLabel: 'Retour à la mission',
      onBack: _back,
    );

    if (!m.inProgress) {
      return JourneyScaffold(
        header: header,
        body: const ParcErrorAlert(message: 'Un plein se saisit pendant la mission, après le contrôle de départ.'),
        footer: [ParcOutlinedButton(label: 'Retour', height: 48, onPressed: _back)],
      );
    }

    final saved = _saved;
    if (_done != null && saved != null) {
      final recap = [
        '${FrenchDates.km(saved.odometerKm)} km',
        if (saved.station != null) saved.station!,
        saved.full ? 'réservoir rempli' : 'plein partiel',
      ].join(' · ');
      return JourneyScaffold(
        offlineBanner: true,
        header: header,
        bodyPadding: const EdgeInsets.fromLTRB(20, 40, 20, 18),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResultView(
              icon: ParcIcons.checkBold,
              iconBg: ParcColors.successBg,
              iconColor: ParcColors.success,
              topPadding: 18,
              title: 'Plein enregistré',
              message: Text(
                _done == SubmitResult.queued
                    ? 'Enregistré sur le téléphone : il sera envoyé dès le retour du réseau.'
                    : 'Le plein est rattaché à la mission ${m.number}. Le gestionnaire le retrouve dans Carburant › Pleins.',
                textAlign: TextAlign.center,
                style: parcText(15, color: ParcColors.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 18),
            WhiteCard(
              radius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatLitres(saved.litres)} L · ${FrenchDates.km(saved.amount)} FCFA',
                    style: parcText(15, weight: 800),
                  ),
                  const SizedBox(height: 2),
                  Text(recap, style: parcText(13, color: ParcColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
        footer: [ParcPrimaryButton(label: 'Reprendre la mission', onPressed: _back)],
      );
    }

    final departure = _departureKm;
    final km = parseKm(_odometer.text);
    Widget? hint;
    if (departure != null && km != null) {
      final departureKm = FrenchDates.km(departure);
      final verdict = checkOdometer(
        km: km,
        reference: departure,
        since: widget.mission.departureCheck?.at,
        now: ref.watch(clockProvider)(),
      );
      hint = switch (verdict) {
        OdometerVerdict.low => KmHint('Inférieur au départ de la mission ($departureKm km)', ok: false),
        OdometerVerdict.ok => KmHint('Cohérent avec le départ de la mission ($departureKm km)', ok: true),
        OdometerVerdict.unusual => KmHint(
            'Écart inhabituel : ${FrenchDates.km(km - departure)} km depuis le départ de la mission ($departureKm km). '
            'Vérifiez le compteur.',
            ok: false,
          ),
      };
    }

    return JourneyScaffold(
      offlineBanner: true,
      header: header,
      bodyPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldCaption('Kilométrage au compteur'),
          const SizedBox(height: 6),
          OdometerInput(
            fieldKey: const Key('fuel.odometer'),
            controller: _odometer,
            onChanged: () => setState(() {}),
            hint: hint,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NumberField(
                  label: 'Litres',
                  unit: 'L',
                  fieldKey: const Key('fuel.litres'),
                  controller: _litres,
                  decimal: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  label: 'Montant',
                  unit: 'FCFA',
                  fieldKey: const Key('fuel.amount'),
                  controller: _amount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const FieldCaption('Réservoir rempli'),
          const SizedBox(height: 6),
          SegmentedChoice(
            labels: const ['Oui, le plein', 'Non, partiel'],
            selected: _full ? 0 : 1,
            selectedColors: const [ParcColors.primary, ParcColors.primary],
            onChanged: (i) => setState(() => _full = i == 0),
          ),
          const SizedBox(height: 16),
          const FieldCaption('Station', suffix: '(facultatif)'),
          const SizedBox(height: 6),
          ParcTextField(key: const Key('fuel.station'), controller: _station, height: 48, fontSize: 15),
          const SizedBox(height: 16),
          const FieldCaption('Ticket de caisse'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (i, _) in _tickets.indexed) CapturedTile(label: 'Ticket ${i + 1}', size: 84, icon: ParcIcons.checkSquare),
              if (_tickets.length < maxTickets) AddCaptureButton(label: 'Photographier le ticket', size: 84, missing: _ticketMissing, onPressed: _takeTicket),
            ],
          ),
          if (_ticketMissing) ...[
            const SizedBox(height: 8),
            Text(
              'Photographiez le ticket de caisse pour enregistrer le plein.',
              style: parcText(13, weight: 700, color: ParcColors.danger),
            ),
          ],
          const SizedBox(height: 6),
          Text('1 à 2 photos. Le ticket est obligatoire.', style: parcText(12, color: ParcColors.textMuted)),
          if (_error != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _error!)],
        ],
      ),
      footer: [JourneyActionButton(label: 'Enregistrer le plein', busy: _busy, onPressed: _save)],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.unit,
    required this.fieldKey,
    required this.controller,
    this.decimal = false,
  });

  final String label;
  final String unit;
  final Key fieldKey;
  final TextEditingController controller;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldCaption(label),
        const SizedBox(height: 6),
        ParcTextField(
          key: fieldKey,
          controller: controller,
          height: 52,
          fontSize: 18,
          fontWeight: 800,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          trailing: Text(unit, style: parcText(13, weight: 700, color: ParcColors.textMuted)),
        ),
      ],
    );
  }
}
