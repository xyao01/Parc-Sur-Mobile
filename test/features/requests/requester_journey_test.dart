import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/features/auth/domain/mobile_profile.dart';
import 'package:parc_sur_mobile/features/missions/domain/mission_flow_config.dart';
import 'package:parc_sur_mobile/features/requests/data/requests_gateway.dart';
import 'package:parc_sur_mobile/features/requests/data/requests_providers.dart';
import 'package:parc_sur_mobile/features/requests/domain/request_config.dart';
import 'package:parc_sur_mobile/features/requests/presentation/my_requests_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/request_decision_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/request_detail_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/request_end_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/request_form_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/request_rating_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/request_sent_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/request_summary_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/request_tracking_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/requester_home_screen.dart';

import '../../helpers/fake_requests_gateway.dart';
import '../../helpers/pump_app.dart';

const requester = MobileProfile(firstName: 'Koffi', lastName: 'Ouattara', roles: {AppRole.demandeur});

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

FakeRequestsGateway gateway() => FakeRequestsGateway(rows: prototypeRequestRows(prototypeNow));

Future<FakeRequestsGateway> pumpRequester(WidgetTester tester, String location, {FakeRequestsGateway? requests}) async {
  final g = requests ?? gateway();
  await pumpApp(tester, location: location, profile: requester, requests: g);
  return g;
}

/// Sets the date fields of the form (pickers are covered by Flutter itself).
Future<void> setDates(WidgetTester tester, String key, DateTime departure, DateTime plannedReturn) async {
  final container = ProviderScope.containerOf(tester.element(find.byType(RequestFormScreen)));
  container.read(requestDraftProvider(key))
    ..departure = departure
    ..plannedReturn = plannedReturn;
  await tester.tap(find.bySemanticsLabel('Ajouter un passager'));
  await tester.tap(find.bySemanticsLabel('Retirer un passager'));
  await tester.pumpAndSettle();
}

void main() {
  group('D01 · Accueil demandeur', () {
    testWidgets('renders the requests from Supabase like the prototype', (tester) async {
      await pumpRequester(tester, '/demandes');

      expect(find.byType(RequesterHomeScreen), findsOneWidget);
      expect(find.text('Bonjour, Koffi'), findsOneWidget);
      expect(find.text('KO'), findsOneWidget);
      expect(find.text('Demandeur'), findsOneWidget);
      expect(find.text('Nouvelle demande de véhicule'), findsOneWidget);
      expect(find.text('Mission, dates, passagers'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('requester.stat.pending'))).data, '1');
      expect(tester.widget<Text>(find.byKey(const Key('requester.stat.inProgress'))).data, '1');
      expect(tester.widget<Text>(find.byKey(const Key('requester.stat.validated'))).data, '1');
      expect(find.text('MISSION EN COURS'), findsOneWidget);
      expect(find.text('D-0139'), findsOneWidget);
      expect(find.text('Yamoussoukro'), findsOneWidget);
      expect(find.text('Land Cruiser · chauffeur Yao Kouadio · retour mer. 17:00'), findsOneWidget);
      expect(find.text('DERNIÈRE DEMANDE'), findsOneWidget);
      expect(find.text('Bouaké'), findsOneWidget);
      expect(find.text('Jeu. 5 → sam. 7 nov. · 3 passagers'), findsOneWidget);
      expect(find.text('Voir toutes mes demandes'), findsOneWidget);
      for (final tab in ['Accueil', 'Mes demandes', 'Alertes', 'Profil']) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading failure: message and retry', (tester) async {
      await pumpRequester(tester, '/demandes', requests: FakeRequestsGateway(error: const RequestsGatewayException('x')));
      expect(find.text('Impossible de charger vos demandes.'), findsOneWidget);
    });
  });

  group('D02 → D04 · nouvelle demande', () {
    testWidgets('form, checks, summary, attestation, then sent to Supabase', (tester) async {
      final g = await pumpRequester(tester, '/demandes');
      await tapText(tester, 'Nouvelle demande de véhicule');

      expect(find.byType(RequestFormScreen), findsOneWidget);
      expect(find.text('Véhicule de mission'), findsOneWidget);
      await tapText(tester, 'Vérifier ma demande');
      expect(find.text('Indiquez l’objet de la mission.'), findsOneWidget);
      expect(find.text('Indiquez la destination, ex. Bouaké.'), findsOneWidget);
      expect(find.text('Indiquez la date et l’heure de départ.'), findsOneWidget);
      // tr-04: focus goes to the first field in error.
      final purpose = tester.widget<EditableText>(
        find.descendant(of: find.byKey(const Key('request.purpose')), matching: find.byType(EditableText)),
      );
      expect(purpose.focusNode.hasFocus, isTrue);

      await tester.enterText(find.byKey(const Key('request.purpose')), 'Inspection de dépôts pétroliers');
      await tester.enterText(find.byKey(const Key('request.destination')), 'Bouaké');
      await tester.pump();
      // A corrected field loses its message at once; the others keep theirs until fixed.
      expect(find.text('Indiquez l’objet de la mission.'), findsNothing);
      expect(find.text('Indiquez la destination, ex. Bouaké.'), findsNothing);
      expect(find.text('Indiquez la date et l’heure de départ.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('request.purpose')), ' ');
      await tester.pump();
      expect(find.text('Indiquez l’objet de la mission.'), findsOneWidget, reason: 'emptied again after a check');
      await tester.enterText(find.byKey(const Key('request.purpose')), 'Inspection de dépôts pétroliers');
      await tester.enterText(find.byKey(const Key('request.notes')), 'Matériel de contrôle (2 caisses).');
      await setDates(tester, newRequestDraftKey, DateTime(2026, 11, 5, 7), DateTime(2026, 11, 7, 18));
      await tester.tap(find.bySemanticsLabel('Ajouter un passager'));
      await tester.tap(find.bySemanticsLabel('Ajouter un passager'));
      await tester.pump();
      await tapText(tester, 'Vérifier ma demande');

      expect(find.byType(RequestSummaryScreen), findsOneWidget);
      expect(find.text("Vérifiez avant d'envoyer"), findsOneWidget);
      expect(find.text('Jeu. 5 nov. · 07:00'), findsOneWidget);
      expect(find.text('Sam. 7 nov. · 18:00'), findsOneWidget);
      expect(find.text('Demandé'), findsOneWidget);
      expect(find.text("Cochez l'attestation pour envoyer"), findsOneWidget);
      await tapText(tester, "Cochez l'attestation pour envoyer");
      expect(g.created, isEmpty, reason: 'attestation required');

      await tapText(tester, "J'atteste que cette mission est à usage strictement professionnel.");
      await tapText(tester, 'Envoyer la demande');

      expect(g.created.single, allOf(
        containsPair('motif', 'Inspection de dépôts pétroliers'),
        containsPair('destination', 'Bouaké'),
        containsPair('passagers', 3),
        containsPair('avec_chauffeur', true),
        containsPair('commentaire', 'Matériel de contrôle (2 caisses).'),
      ));
      expect(find.byType(RequestSentScreen), findsOneWidget);
      expect(find.textContaining('Étape'), findsNothing);
      expect(find.text('Votre demande est envoyée'), findsOneWidget);
      expect(find.textContaining('D-0150', findRichText: true), findsWidgets);
      expect(find.text('Examen par le gestionnaire'), findsOneWidget);

      await tapText(tester, 'Suivre mes demandes');
      expect(find.byType(MyRequestsScreen), findsOneWidget);
    });
  });

  group('D05 · Mes demandes', () {
    testWidgets('lists the requests and filters them by state', (tester) async {
      await pumpRequester(tester, '/mes-demandes');

      expect(find.textContaining('Étape'), findsNothing, reason: 'opened from the menu: no journey step (17/11/2026)');
      for (final d in ['Bouaké', 'Yamoussoukro', 'Abengourou', 'San-Pédro', 'Daloa']) {
        expect(find.text(d), findsOneWidget);
      }
      expect(find.text('Refusée'), findsOneWidget);

      await tapText(tester, 'Terminées');
      expect(find.text('Daloa'), findsOneWidget);
      expect(find.text('Bouaké'), findsNothing);

      await tapText(tester, 'En attente');
      expect(find.text('Bouaké'), findsOneWidget);
      expect(find.text('Daloa'), findsNothing);
      await tapText(tester, 'Bouaké');
      expect(find.byType(RequestDetailScreen), findsOneWidget);
    });
  });

  group('D05 · actualisation (bug 19/11/2026: decision made on the web not shown)', () {
    FakeRequestsGateway pendingOnly() =>
        FakeRequestsGateway(rows: [prototypeRequestRows(prototypeNow).first]);

    void decide(FakeRequestsGateway g) => g.rows = [
          {...g.rows!.first, 'statut': 'validee', 'vehicule': 'Toyota Corolla · AB-1234-CI', 'chauffeur': 'Yao Kouadio'},
        ];

    testWidgets('pulling the short list down shows the decision', (tester) async {
      final g = await pumpRequester(tester, '/mes-demandes', requests: pendingOnly());
      expect(find.text('En attente'), findsWidgets);
      decide(g);

      await tester.fling(find.text('Bouaké'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Validée'), findsOneWidget);
    });

    testWidgets('coming back to the app reloads the requests', (tester) async {
      final g = await pumpRequester(tester, '/mes-demandes', requests: pendingOnly());
      decide(g);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Validée'), findsOneWidget);
    });
  });

  group('D06 · détail, annulation, modification', () {
    testWidgets('cancels a pending request after confirmation', (tester) async {
      final g = await pumpRequester(tester, '/demandes/m-142');

      expect(find.text('Demande D-0142'), findsOneWidget);
      expect(find.textContaining('Étape'), findsNothing);
      expect(find.text('En attente de validation par le gestionnaire'), findsOneWidget);
      expect(find.text('Demande envoyée'), findsOneWidget);

      await tapText(tester, 'Annuler');
      expect(find.text('Annuler cette demande ?'), findsOneWidget);
      await tapText(tester, 'Non, la conserver');
      expect(g.cancelled, isEmpty);

      await tapText(tester, 'Annuler');
      await tapText(tester, 'Oui, annuler la demande');
      expect(g.cancelled.single, ('m-142', RequestConfig.cancelReason));
      expect(find.text('Demande annulée'), findsOneWidget);
      expect(find.text("Retour à l'accueil"), findsOneWidget);
    });

    testWidgets('« Modifier » reopens the form and saves the changes', (tester) async {
      final g = await pumpRequester(tester, '/demandes/m-142');
      await tapText(tester, 'Modifier');

      expect(find.byType(RequestFormScreen), findsOneWidget);
      expect(find.text('Inspection de dépôts pétroliers'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('request.destination')), 'Bouaké, Katiola');
      await tapText(tester, 'Vérifier ma demande');
      await tapText(tester, "J'atteste que cette mission est à usage strictement professionnel.");
      await tapText(tester, 'Envoyer la demande');

      expect(g.updated['m-142'], containsPair('destination', 'Bouaké, Katiola'));
      expect(find.byType(RequestDetailScreen), findsOneWidget);
    });
  });

  group('D07 · décision', () {
    testWidgets('validated: vehicle, driver and departure', (tester) async {
      await pumpRequester(tester, '/demandes/m-140/decision');
      expect(find.byType(RequestDecisionScreen), findsOneWidget);
      expect(find.text('D-0140'), findsOneWidget);
      expect(find.textContaining('Étape'), findsNothing);
      expect(find.text('Demande validée'), findsOneWidget);
      expect(find.text('Toyota Prado · 2087 FC 01'), findsOneWidget);
      expect(find.text('Aya Koné'), findsOneWidget);
      expect(find.text('Rendez-vous de départ'), findsOneWidget);
      await tapText(tester, 'Suivre ma mission');
      expect(find.byType(RequestTrackingScreen), findsOneWidget);
    });

    testWidgets('refused: reason, and a new request', (tester) async {
      await pumpRequester(tester, '/demandes/m-131/decision');
      expect(find.text('Demande refusée'), findsOneWidget);
      expect(find.text('Motif du refus'), findsOneWidget);
      expect(find.text('Aucun véhicule disponible à ces dates'), findsOneWidget);
      await tapText(tester, 'Refaire une demande');
      expect(find.byType(RequestFormScreen), findsOneWidget);
    });
  });

  group('D08 · suivi de la mission', () {
    testWidgets('mission under way, and problem report', (tester) async {
      final g = await pumpRequester(tester, '/demandes/m-139/suivi');
      expect(find.text('Mission en cours'), findsOneWidget);
      expect(find.textContaining('Étape'), findsNothing);
      expect(find.text('D-0139 · Destination'), findsOneWidget);
      expect(find.text('Yamoussoukro'), findsWidgets);
      expect(find.text('Yao Kouadio'), findsOneWidget);
      expect(find.text('Chauffeur · Land Cruiser · 1150 FB 01'), findsOneWidget);

      await tapText(tester, 'Signaler un problème');
      await tapText(tester, 'Envoyer au gestionnaire');
      expect(find.text('Choisissez le type de problème.'), findsOneWidget);
      await tapText(tester, 'Retard important');
      await tapText(tester, 'Envoyer au gestionnaire');
      expect(find.text('Signalement envoyé'), findsOneWidget);
      expect(g.problems.single, containsPair('kind', 'Retard important'));
    });

    testWidgets('the report is refused while the server has no such step', (tester) async {
      final g = gateway();
      await pumpRequester(tester, '/demandes/m-139/suivi', requests: g);
      await tapText(tester, 'Signaler un problème');
      await tapText(tester, 'Retard important');
      g.error = const RequestsGatewayException(MissionFlowConfig.unavailableMessage);
      await tapText(tester, 'Envoyer au gestionnaire');
      expect(find.text(MissionFlowConfig.unavailableMessage), findsOneWidget);
    });
  });

  group('D09 → D10 · fin de mission et évaluation', () {
    testWidgets('confirmation, rating required, then sent', (tester) async {
      final g = await pumpRequester(tester, '/mes-demandes');
      await tapText(tester, 'Daloa');

      expect(find.byType(RequestEndScreen), findsOneWidget);
      expect(find.text('D-0118'), findsOneWidget);
      expect(find.text('Mission terminée'), findsOneWidget);
      expect(find.text('Cochez la confirmation pour continuer'), findsOneWidget);
      await tapText(tester, "Je confirme que la mission s'est déroulée comme prévu.");
      await tapText(tester, 'Continuer');

      expect(find.byType(RequestRatingScreen), findsOneWidget);
      expect(find.text("Comment s'est passée la mission ?"), findsOneWidget);
      await tapText(tester, 'Envoyer et clôturer la demande');
      expect(find.text('Donnez une note de 1 à 5 pour clôturer.'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('4 sur 5'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Ponctualité');
      await tapText(tester, 'Envoyer et clôturer la demande');
      expect(g.ratings.single, allOf(containsPair('rating', 4), containsPair('tags', ['Ponctualité'])));
      expect(find.text('Demande clôturée'), findsOneWidget);
    });
  });
}
