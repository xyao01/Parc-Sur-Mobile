import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../data/requests_gateway.dart';
import '../data/requests_providers.dart';
import '../domain/request_draft.dart';
import 'request_widgets.dart';

/// Mob-D03 · Récapitulatif avant envoi: creates the request (`demande_vehicule`), or saves the edit.
class RequestSummaryScreen extends ConsumerStatefulWidget {
  const RequestSummaryScreen({super.key, this.editId});

  final String? editId;

  @override
  ConsumerState<RequestSummaryScreen> createState() => _RequestSummaryScreenState();
}

class _RequestSummaryScreenState extends ConsumerState<RequestSummaryScreen> {
  late final String _key = widget.editId ?? newRequestDraftKey;
  late final RequestDraft _draft = ref.read(requestDraftProvider(_key));
  bool _attested = false;
  bool _busy = false;
  String? _error;

  Future<void> _send() async {
    if (!_attested || _busy) return;
    final invalid = _draft.validate(ref.read(clockProvider)());
    if (invalid.isNotEmpty) {
      setState(() => _error = invalid.values.first);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final gateway = ref.read(requestsGatewayProvider);
      final editId = widget.editId;
      final String route;
      if (editId == null) {
        final id = await gateway.create(_draft.toRow());
        route = Routes.requestSent(id);
      } else {
        await gateway.update(editId, _draft.toRow());
        route = Routes.requestDetail(editId);
      }
      ref.invalidate(myRequestsProvider);
      ref.invalidate(requestDraftProvider(_key));
      if (mounted) context.go(route);
    } on RequestsGatewayException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'La demande n’a pas pu être envoyée. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _draft;
    final departure = d.departure;
    final plannedReturn = d.plannedReturn;
    return JourneyScaffold(
      header: JourneyHeader(
        title: 'Récapitulatif',
        subtitle: "Vérifiez avant d'envoyer",
        backLabel: 'Retour au formulaire',
        onBack: () => requestBack(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (departure != null && plannedReturn != null)
            RequestSummaryCard(
              destination: d.destination.trim(),
              purpose: d.purpose.trim(),
              departure: departure,
              plannedReturn: plannedReturn,
              passengers: d.passengers,
              withDriver: d.withDriver,
              notes: d.notes,
              footer: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TextLink('Modifier la demande', onTap: () => requestBack(context)),
                ),
              ),
            ),
          const SizedBox(height: 14),
          const InfoNote('Le véhicule et le chauffeur seront choisis par le gestionnaire. Vous serez notifié dès la décision.'),
          const SizedBox(height: 14),
          ConfirmBox(
            text: "J'atteste que cette mission est à usage strictement professionnel.",
            checked: _attested,
            onTap: () => setState(() => _attested = !_attested),
          ),
          if (_error != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _error!)],
        ],
      ),
      footer: [
        _attested
            ? JourneyActionButton(label: 'Envoyer la demande', busy: _busy, onPressed: _send)
            : JourneyActionButton(label: "Cochez l'attestation pour envoyer", ready: false, onPressed: () {}),
      ],
    );
  }
}
