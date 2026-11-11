import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../domain/request_config.dart';
import 'demandeur_nav.dart';

/// Mobile · Nouvelle demande (demandeur).
class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _purpose = TextEditingController();
  final _destination = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _departure;
  DateTime? _return;
  int _passengers = RequestConfig.minPassengers;
  bool _needDriver = RequestConfig.needDriverByDefault;

  @override
  void dispose() {
    _purpose.dispose();
    _destination.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _canRemove => _passengers > RequestConfig.minPassengers;
  bool get _canAdd => RequestConfig.maxPassengers == null || _passengers < RequestConfig.maxPassengers!;

  Future<void> _pickDateTime({required bool departure}) async {
    final now = DateTime.now();
    final initial = (departure ? _departure : _return) ?? _departure ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => departure ? _departure = value : _return = value);
  }

  void _back() => context.canPop() ? context.pop() : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        children: [
          _Header(onBack: _back),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ParcLabeled(
                  label: 'Motif de la mission',
                  labelSize: 13,
                  child: ParcTextField(controller: _purpose, height: 48, fontSize: 15, textInputAction: TextInputAction.next),
                ),
                const SizedBox(height: 16),
                ParcLabeled(
                  label: 'Destination(s)',
                  labelSize: 13,
                  child: ParcTextField(controller: _destination, height: 48, fontSize: 15, textInputAction: TextInputAction.next),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DateTimeField(label: 'Départ', value: _departure, onTap: () => _pickDateTime(departure: true)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateTimeField(label: 'Retour', value: _return, onTap: () => _pickDateTime(departure: false)),
                    ),
                  ],
                ),
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
                        onTap: _canRemove ? () => setState(() => _canRemove ? _passengers-- : null) : null,
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 36,
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            '$_passengers',
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
                        onTap: _canAdd ? () => setState(() => _canAdd ? _passengers++ : null) : null,
                      ),
                    ],
                  ),
                ),
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
                            Text('Un chauffeur disponible sera affecté', style: parcText(12, color: ParcColors.textMuted)),
                          ],
                        ),
                      ),
                      _ParcSwitch(
                        key: const Key('request.needDriver'),
                        value: _needDriver,
                        semanticLabel: "Besoin d'un chauffeur",
                        onChanged: (v) => setState(() => _needDriver = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ParcLabeled(
                  label: 'Précisions (facultatif)',
                  labelSize: 13,
                  child: ParcTextField(
                    controller: _notes,
                    height: null,
                    maxLines: 2,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    hintText: 'Bagages, matériel à transporter…',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: ParcColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ParcIcon(ParcIcons.info, size: 18, color: ParcColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Votre demande sera examinée par un administrateur. Vous recevrez une notification dès sa validation.',
                          style: parcText(12, color: ParcColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            decoration: const BoxDecoration(
              color: ParcColors.surface,
              border: Border(top: BorderSide(color: ParcColors.divider)),
            ),
            // Submission is not wired to a backend yet (see README).
            child: ParcPrimaryButton(label: 'Envoyer la demande', height: 52, onPressed: () {}),
          ),
        ],
      ),
      bottomNavigationBar: const DemandeurBottomNav(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      color: ParcColors.primary,
      padding: EdgeInsets.fromLTRB(20, 20 + top, 20, 18),
      child: Row(
        children: [
          ParcHeaderBackButton(
            semanticLabel: 'Retour',
            onPressed: onBack,
            icon: const ParcIcon(ParcIcons.back, size: 20, color: ParcColors.surface),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text('Nouvelle demande', style: parcText(18, weight: 800, color: ParcColors.surface))),
              Text('Véhicule de mission', style: parcText(12, color: ParcColors.onPrimaryMuted)),
            ],
          ),
        ],
      ),
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
              child: Text(
                v == null ? '' : FrenchDates.shortDayTime(v),
                style: parcText(14),
                overflow: TextOverflow.ellipsis,
              ),
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

/// 52×32 pill switch from the prototype.
class _ParcSwitch extends StatelessWidget {
  const _ParcSwitch({super.key, required this.value, required this.onChanged, required this.semanticLabel});

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
