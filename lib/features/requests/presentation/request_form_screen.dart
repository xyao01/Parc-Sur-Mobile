import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../data/requests_providers.dart';
import '../domain/request_config.dart';
import '../domain/request_draft.dart';
import 'request_widgets.dart';

/// Mob-D02 · Formulaire de demande — new request, or edit of a pending one ([editId]).
class RequestFormScreen extends StatelessWidget {
  const RequestFormScreen({super.key, this.editId});

  final String? editId;

  @override
  Widget build(BuildContext context) {
    final id = editId;
    if (id == null) return const _Form(draftKey: newRequestDraftKey);
    return RequestLoader(
      requestId: id,
      builder: (context, r, _) => _Form(draftKey: id, editing: true, fill: (d) => d.fillFrom(r)),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.draftKey, this.editing = false, this.fill});

  final String draftKey;
  final bool editing;
  final void Function(RequestDraft)? fill;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final RequestDraft _draft = ref.read(requestDraftProvider(widget.draftKey));
  late final TextEditingController _purpose;
  late final TextEditingController _destination;
  late final TextEditingController _notes;
  Map<String, String> _errors = const {};

  @override
  void initState() {
    super.initState();
    widget.fill?.call(_draft);
    _purpose = TextEditingController(text: _draft.purpose)..addListener(() => _draft.purpose = _purpose.text);
    _destination = TextEditingController(text: _draft.destination)
      ..addListener(() => _draft.destination = _destination.text);
    _notes = TextEditingController(text: _draft.notes)..addListener(() => _draft.notes = _notes.text);
  }

  @override
  void dispose() {
    _purpose.dispose();
    _destination.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool departure}) async {
    final now = ref.read(clockProvider)();
    final initial = (departure ? _draft.departure : _draft.plannedReturn) ?? _draft.departure ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => departure ? _draft.departure = value : _draft.plannedReturn = value);
  }

  void _check() {
    FocusScope.of(context).unfocus();
    final errors = _draft.validate(ref.read(clockProvider)());
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    context.push(widget.editing ? Routes.editRequestSummary(widget.draftKey) : Routes.newRequestSummary);
  }

  void _passengers(int delta) {
    final n = _draft.passengers + delta;
    if (n < RequestConfig.minPassengers || n > RequestConfig.maxPassengers) return;
    setState(() => _draft.passengers = n);
  }

  Widget _error(String field) =>
      _errors[field] == null ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(top: 6), child: FieldError(_errors[field]!));

  @override
  Widget build(BuildContext context) {
    final d = _draft;
    return JourneyScaffold(
      header: JourneyHeader(
        title: widget.editing ? 'Modifier la demande' : 'Nouvelle demande',
        subtitle: 'Véhicule de mission · ${stepLabel(2)}',
        backLabel: widget.editing ? 'Retour à la demande' : "Retour à l'accueil",
        onBack: () => requestBack(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParcLabeled(
            label: 'Motif de la mission',
            labelSize: 13,
            child: ParcTextField(
              key: const Key('request.purpose'),
              controller: _purpose,
              height: 48,
              fontSize: 15,
              textInputAction: TextInputAction.next,
            ),
          ),
          _error('purpose'),
          const SizedBox(height: 16),
          ParcLabeled(
            label: 'Destination(s)',
            labelSize: 13,
            child: ParcTextField(
              key: const Key('request.destination'),
              controller: _destination,
              height: 48,
              fontSize: 15,
              textInputAction: TextInputAction.next,
            ),
          ),
          _error('destination'),
          const SizedBox(height: 16),
          _DateTimeField(label: 'Départ', value: d.departure, onTap: () => _pick(departure: true)),
          _error('departure'),
          const SizedBox(height: 16),
          _DateTimeField(label: 'Retour', value: d.plannedReturn, onTap: () => _pick(departure: false)),
          _error('return'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: parcFieldDecoration(),
            child: Row(
              children: [
                Expanded(child: Text('Passagers', style: parcText(14, weight: 700))),
                _StepperButton(
                  label: 'Retirer un passager',
                  symbol: '−',
                  onTap: d.passengers > RequestConfig.minPassengers ? () => _passengers(-1) : null,
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 36,
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      '${d.passengers}',
                      key: const Key('request.passengers'),
                      textAlign: TextAlign.center,
                      style: parcText(18, weight: 800),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _StepperButton(
                  label: 'Ajouter un passager',
                  symbol: '+',
                  onTap: d.passengers < RequestConfig.maxPassengers ? () => _passengers(1) : null,
                ),
              ],
            ),
          ),
          _error('passengers'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: parcFieldDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Besoin d'un chauffeur", style: parcText(14, weight: 700)),
                      Text(
                        d.withDriver ? 'Un chauffeur disponible sera affecté' : 'Vous conduirez vous-même le véhicule',
                        style: parcText(12, color: ParcColors.textMuted),
                      ),
                    ],
                  ),
                ),
                _ParcSwitch(
                  value: d.withDriver,
                  semanticLabel: "Besoin d'un chauffeur",
                  onChanged: (v) => setState(() => d.withDriver = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const FieldCaption('Précisions', suffix: '(facultatif)'),
          const SizedBox(height: 6),
          ParcTextField(
            key: const Key('request.notes'),
            controller: _notes,
            height: null,
            maxLines: 2,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            hintText: 'Bagages, matériel à transporter…',
          ),
        ],
      ),
      footer: [ParcPrimaryButton(label: 'Vérifier ma demande', onPressed: _check)],
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return ParcLabeled(
      label: label,
      labelSize: 13,
      child: Semantics(
        button: true,
        label: label,
        value: v == null ? null : FrenchDates.shortDayTime(v),
        excludeSemantics: true,
        child: Material(
          color: ParcColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ParcColors.inputBorder, width: 1.5),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Text(v == null ? '' : FrenchDates.shortDayTime(v), style: parcText(15)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.label, required this.symbol, required this.onTap});

  final String label;
  final String symbol;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: ParcColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: Text(symbol, style: parcText(22, weight: 700, color: ParcColors.primary))),
          ),
        ),
      ),
    );
  }
}

/// 52×32 pill switch of the prototype.
class _ParcSwitch extends StatelessWidget {
  const _ParcSwitch({required this.value, required this.onChanged, required this.semanticLabel});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      toggled: value,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: value ? ParcColors.primary : ParcColors.checkboxBorder,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: ParcColors.surface, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
