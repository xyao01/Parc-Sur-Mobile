import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/missions/data/missions_gateway.dart';
import 'package:parc_sur_mobile/features/missions/domain/mission_flow_config.dart';
import 'package:parc_sur_mobile/features/missions/presentation/arrival_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/closure_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/departure_preparation_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/departure_validation_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/driver_home_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/end_check_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/mission_details_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/mission_in_progress_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/new_request_notice_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/request_response_screen.dart';

import '../../helpers/fake_missions_gateway.dart';
import '../../helpers/pump_app.dart';

/// Tuesday 3 November 2026, 09:16: D-0142 left at 07:02.
final duringMission = DateTime(2026, 11, 3, 9, 16);

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enterKm(WidgetTester tester, Key key, String value) async {
  await tester.enterText(find.byKey(key), value);
  await tester.pump();
}

FakeMissionsGateway journeyGateway() => FakeMissionsGateway(
      rows: prototypeMissionRows(prototypeNow),
      pending: prototypePendingRows(prototypeNow),
    );

void main() {
  group('C01 · Accueil chauffeur', () {
    testWidgets('renders the driver home from Supabase like the prototype', (tester) async {
      await pumpApp(tester, location: '/missions', missions: journeyGateway());

      expect(find.byType(DriverHomeScreen), findsOneWidget);
      expect(find.text('Bonjour, Yao'), findsOneWidget);
      expect(find.text('YK'), findsOneWidget);
      expect(find.text('Chauffeur'), findsOneWidget);
      expect(find.text('Mardi 3 novembre'), findsOneWidget);
      expect(find.text('Je suis disponible'), findsOneWidget);
      expect(find.text("Mission aujourd'hui"), findsOneWidget);
      expect(find.text('Nouvelle demande'), findsOneWidget);
      expect(find.text('À venir'), findsOneWidget);

      expect(find.text('NOUVELLE DEMANDE'), findsOneWidget);
      expect(find.text('À répondre'), findsOneWidget);
      expect(find.text('Reçue à 08:12'), findsOneWidget);
      expect(find.text('Bouaké'), findsOneWidget);
      expect(find.text('Jeu. 5 nov. 07:00 → sam. 7 nov. 18:00 · Koffi Ouattara · 3 passagers'), findsOneWidget);

      expect(find.text('MISSION DU JOUR'), findsOneWidget);
      expect(find.text('Départ à 07:30'), findsOneWidget);
      expect(find.text('D-0139'), findsOneWidget);
      expect(find.text('Yamoussoukro'), findsOneWidget);
      expect(find.text('Land Cruiser · 1150 FB 01 · Koffi Ouattara · 2 passagers'), findsOneWidget);
      expect(find.text('Commencer le contrôle de départ'), findsOneWidget);
      for (final tab in ['Missions', 'Planning', 'Alertes', 'Profil']) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('counts 1 today, 1 new request, 2 upcoming', (tester) async {
      await pumpApp(tester, location: '/missions', missions: journeyGateway());
      expect(find.byKey(const Key('home.stat.today')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('home.stat.today'))).data, '1');
      expect(tester.widget<Text>(find.byKey(const Key('home.stat.new'))).data, '1');
      expect(tester.widget<Text>(find.byKey(const Key('home.stat.upcoming'))).data, '2');
    });

    testWidgets('no request awaiting an answer: no « Nouvelle demande » card', (tester) async {
      await pumpApp(tester, location: '/missions', missions: FakeMissionsGateway(rows: prototypeMissionRows(prototypeNow)));
      expect(find.text('NOUVELLE DEMANDE'), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('home.stat.new'))).data, '0');
    });

    testWidgets('a mission whose return is recorded shows « Retour enregistré », not the departure time', (tester) async {
      final rows = inProgressRows(duringMission);
      rows.single['controleRetour'] = {'id': 'c-2', 'saisiLe': duringMission.toUtc().toIso8601String(), 'kilometrage': 61520};
      await pumpApp(tester, location: '/missions', now: duringMission, missions: FakeMissionsGateway(rows: rows));
      expect(find.text('Retour enregistré'), findsOneWidget);
      expect(find.textContaining('Départ à'), findsNothing);
      expect(find.text('Reprendre la mission en cours'), findsNothing);
    });

    testWidgets('a mission under way is resumed from the home', (tester) async {
      await pumpApp(tester, location: '/missions', now: duringMission, missions: FakeMissionsGateway(rows: inProgressRows(duringMission)));
      await tapText(tester, 'Reprendre la mission en cours');
      expect(find.byType(MissionInProgressScreen), findsOneWidget);
    });
  });

  group('C02 → C04 · nouvelle demande, détails, réponse', () {
    testWidgets('notification then details of the request', (tester) async {
      await pumpApp(tester, location: '/missions', missions: journeyGateway());
      await tapText(tester, 'À répondre');

      expect(find.byType(NewRequestNoticeScreen), findsOneWidget);
      expect(find.text('Notification'), findsOneWidget);
      expect(find.textContaining('Étape'), findsNothing, reason: 'no journey step in the headers (19/11/2026)');
      expect(find.text('Nouvelle demande de mission'), findsOneWidget);
      expect(find.text("Reçue aujourd'hui à 08:12 · à traiter"), findsOneWidget);
      expect(find.text('Toyota Prado · 3302 EA 01'), findsOneWidget);
      expect(find.text('Jeu. 5 nov. · 07:00'), findsOneWidget);
      expect(find.text('Sam. 7 nov. · 18:00'), findsOneWidget);
      expect(find.text('Répondre plus tard'), findsOneWidget);

      await tapText(tester, 'Voir les détails de la mission');
      expect(find.byType(MissionDetailsScreen), findsOneWidget);
      expect(find.text('D-0142'), findsOneWidget);
      expect(find.text('En attente de votre réponse'), findsOneWidget);
      expect(find.text('Inspection de dépôts pétroliers'), findsOneWidget);
      expect(find.text('3 jours'), findsOneWidget);
      expect(find.text('VÉHICULE'), findsOneWidget);
      expect(find.text('DEMANDEUR'), findsOneWidget);
      expect(find.text('KO'), findsOneWidget);
      expect(find.textContaining('matériel de contrôle à transporter (2 caisses).', findRichText: true), findsOneWidget);
      expect(find.text('Refuser'), findsOneWidget);
      expect(find.text('Accepter'), findsOneWidget);
    });

    testWidgets('« Accepter » sends the answer and offers to prepare the departure', (tester) async {
      final gateway = journeyGateway();
      await pumpApp(tester, location: '/missions/demandes/m-142/details', missions: gateway);
      await tapText(tester, 'Accepter');

      expect(find.byType(RequestResponseScreen), findsOneWidget);
      expect(find.text('D-0142'), findsOneWidget);
      expect(find.text('Mission acceptée'), findsOneWidget);
      expect(gateway.responses.single, containsPair('accept', true));

      await tapText(tester, 'Préparer le départ');
      expect(find.byType(DeparturePreparationScreen), findsOneWidget);
    });

    testWidgets('the answer is refused while the server has no answer step', (tester) async {
      final gateway = journeyGateway()..actionError = const MissionsGatewayException(MissionFlowConfig.unavailableMessage);
      await pumpApp(tester, location: '/missions/demandes/m-142/details', missions: gateway);
      await tapText(tester, 'Accepter');

      expect(find.text(MissionFlowConfig.unavailableMessage), findsOneWidget);
      expect(find.text('Mission acceptée'), findsNothing);
    });

    testWidgets('« Refuser » requires a reason, then sends it', (tester) async {
      final gateway = journeyGateway();
      await pumpApp(tester, location: '/missions/demandes/m-142/details', missions: gateway);
      await tapText(tester, 'Refuser');

      expect(find.textContaining('Motif du refus', findRichText: true), findsOneWidget);
      await tapText(tester, 'Confirmer le refus');
      expect(find.text('Sélectionnez un motif pour envoyer votre refus.'), findsOneWidget);
      expect(gateway.responses, isEmpty);

      await tapText(tester, 'Indisponible à ces dates');
      await tapText(tester, 'Confirmer le refus');
      expect(find.text('Refus envoyé'), findsOneWidget);
      expect(find.textContaining('Indisponible à ces dates', findRichText: true), findsWidgets);
      expect(gateway.responses.single, containsPair('reason', 'Indisponible à ces dates'));
    });
  });

  group('C05 → C06 · préparation et validation du départ', () {
    testWidgets('records the departure check with every checklist point', (tester) async {
      final gateway = journeyGateway();
      await pumpApp(tester, location: '/missions', missions: gateway);
      await tapText(tester, 'Commencer le contrôle de départ');

      expect(find.byType(DeparturePreparationScreen), findsOneWidget);
      expect(find.text('Land Cruiser · 1150 FB 01'), findsOneWidget);
      expect(find.textContaining('Cohérent'), findsNothing, reason: 'empty field: nothing to judge yet (bug 19/11/2026)');
      expect(find.text('Vérification du véhicule'), findsOneWidget);
      expect(find.text('Cric, triangle, trousse de secours'), findsOneWidget);
      expect(find.text('Photos du véhicule'), findsOneWidget);

      await enterKm(tester, const Key('preparation.odometer'), '84 230');
      expect(find.text('Cohérent avec le dernier relevé (84 112 km)'), findsOneWidget);
      for (final label in ['Pneus et roue de secours', 'Feux et clignotants', 'Documents à bord', 'Carrosserie sans nouveau dommage']) {
        await tapText(tester, label);
      }
      await tapText(tester, 'Continuer vers la validation');

      expect(find.byType(DepartureValidationScreen), findsOneWidget);
      expect(find.text('D-0139'), findsOneWidget);
      expect(find.text('84 230 km'), findsOneWidget);
      expect(find.text('3/4'), findsOneWidget);
      expect(find.text('1 anomalie : Propreté et équipements'), findsOneWidget);
      expect(find.text('Cochez la confirmation pour continuer'), findsOneWidget);
      // Values are right-aligned on the same edge, whatever the label length.
      final right = tester.getTopRight(find.text('1 anomalie : Propreté et équipements')).dx;
      expect(tester.getTopRight(find.text('84 230 km')).dx, right);
      expect(tester.getTopRight(find.text('3/4')).dx, right);

      await tapText(tester, 'Je confirme que le véhicule est prêt à partir et que les informations saisies sont exactes.');
      await tapText(tester, 'Valider et démarrer la mission');

      final sent = gateway.recorded.single;
      expect(sent['type'], 'depart');
      expect(sent['km'], 84230);
      expect(sent['fuel'], 'trois_quarts');
      expect(sent['points'], {
        'pneus': 'ok',
        'eclairage': 'ok',
        'documents': 'ok',
        'carrosserie': 'ok',
        'proprete': 'anomalie',
        'equipements': 'anomalie',
      });
      expect(find.byType(MissionInProgressScreen), findsOneWidget);
    });

    testWidgets('refuses an odometer below the last reading (l2-mis-01)', (tester) async {
      await pumpApp(tester, location: '/missions/m-139/preparation', missions: journeyGateway());
      await enterKm(tester, const Key('preparation.odometer'), '84 000');
      expect(find.text('Inférieur au dernier relevé (84 112 km)'), findsOneWidget);
      await tapText(tester, 'Continuer vers la validation');
      expect(find.text('Le kilométrage ne peut pas être inférieur au dernier relevé (84 112 km).'), findsOneWidget);
      expect(find.byType(DepartureValidationScreen), findsNothing);
    });

    testWidgets('warns on a jump beyond 1 500 km a day since the last reading (bug 19/11/2026)', (tester) async {
      await pumpApp(tester, location: '/missions/m-139/preparation', missions: journeyGateway());
      await enterKm(tester, const Key('preparation.odometer'), '85 613');
      expect(find.text('Écart inhabituel : 1 501 km depuis le dernier relevé (84 112 km). Vérifiez le compteur.'), findsOneWidget);
      expect(find.textContaining('Cohérent'), findsNothing);
    });

    testWidgets('asks for the odometer before continuing', (tester) async {
      await pumpApp(tester, location: '/missions/m-139/preparation', missions: journeyGateway());
      await tapText(tester, 'Continuer vers la validation');
      expect(find.text('Indiquez le kilométrage au compteur.'), findsOneWidget);
      expect(find.byType(DepartureValidationScreen), findsNothing);
    });

    testWidgets('« Un problème : bloquer le départ » requires the nature of the problem', (tester) async {
      final gateway = journeyGateway();
      await pumpApp(tester, location: '/missions/m-139/validation', missions: gateway);
      await tapText(tester, 'Un problème : bloquer le départ');

      expect(find.text('Le départ sera bloqué. Le gestionnaire est averti et pourra affecter un autre véhicule.'), findsOneWidget);
      await tapText(tester, 'Bloquer le départ et signaler');
      expect(find.text('Choisissez la nature du problème.'), findsOneWidget);

      await tapText(tester, 'Pneu endommagé');
      await tapText(tester, 'Bloquer le départ et signaler');
      expect(find.text('Départ bloqué'), findsOneWidget);
      expect(gateway.incidents.single, allOf(containsPair('kind', 'Pneu endommagé'), containsPair('blocks', true)));
    });
  });

  group('C07 · mission en cours', () {
    testWidgets('shows the mission under way and reports an incident', (tester) async {
      final gateway = FakeMissionsGateway(rows: inProgressRows(duringMission));
      await pumpApp(tester, location: '/missions/m-142/en-cours', now: duringMission, missions: gateway);

      expect(find.text('Mission en cours'), findsOneWidget);
      expect(find.text('D-0142'), findsOneWidget);
      expect(find.text('Bouaké'), findsWidgets);
      expect(find.text('Heure de départ'), findsOneWidget);
      expect(find.text('07:02'), findsOneWidget);
      expect(find.text('2 h 14'), findsOneWidget);
      expect(find.text('61 480'), findsOneWidget);
      expect(find.text('Demandeur · 3 passagers'), findsOneWidget);

      await tapText(tester, 'Signaler un incident');
      await tapText(tester, "Envoyer l'incident");
      expect(find.text("Choisissez la nature de l'incident."), findsOneWidget);
      await tapText(tester, 'Crevaison');
      await tapText(tester, "Envoyer l'incident");
      expect(find.text('Incident envoyé'), findsOneWidget);
      expect(gateway.missionIncidents.single, allOf(containsPair('kind', 'Crevaison'), containsPair('serious', false)));

      await tapText(tester, 'Reprendre la mission');
      expect(find.text('Incident envoyé'), findsNothing);
    });
  });

  group('C08 → C10 · arrivée, contrôle de fin, clôture', () {
    testWidgets('records the return check with arrival time, odometer, fuel, damage and observations', (tester) async {
      final gateway = FakeMissionsGateway(rows: inProgressRows(duringMission));
      await pumpApp(tester, location: '/missions/m-142/en-cours', now: duringMission, missions: gateway);
      await tapText(tester, 'Je suis arrivé à destination');

      expect(find.byType(ArrivalScreen), findsOneWidget);
      expect(find.text('D-0142'), findsOneWidget);
      expect(find.text('Vous êtes arrivé à'), findsOneWidget);
      expect(find.text('09:16'), findsOneWidget);
      expect(find.text('Enregistrée automatiquement, modifiable si besoin. Départ à 07:02.'), findsOneWidget);

      await enterKm(tester, const Key('arrival.odometer'), '61836');
      expect(find.text('Cohérent : 356 km parcourus depuis le départ (61 480 km)'), findsOneWidget);
      expect(find.text('356 km'), findsOneWidget);
      expect(find.text('2 h 14'), findsOneWidget);
      await tapText(tester, "Enregistrer l'arrivée");

      expect(find.byType(EndCheckScreen), findsOneWidget);
      expect(find.text('Toyota Prado · 3302 EA 01'), findsOneWidget);
      await tapText(tester, '1/4');
      await tapText(tester, 'Signaler un dommage');
      await tapText(tester, 'Avant');
      await tester.enterText(find.byKey(const Key('endCheck.damage')), 'Rayure pare-chocs');
      await tapText(tester, 'Continuer vers la clôture');

      expect(find.byType(ClosureScreen), findsOneWidget);
      expect(find.text('D-0142'), findsOneWidget);
      expect(find.text('Terminée'), findsOneWidget);
      expect(find.text('61 480 → 61 836 km'), findsOneWidget);
      expect(find.text('Mar. 3 nov. · 09:16'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('closure.observations')), 'Route dégradée après Tiébissou');

      await tapText(tester, 'Clôturer la demande');
      expect(gateway.recorded, isEmpty, reason: 'confirmation required');
      await tapText(tester, "Je confirme la fin de la mission et l'exactitude des informations ci-dessus.");
      await tapText(tester, 'Clôturer la demande');

      final sent = gateway.recorded.single;
      expect(sent['type'], 'retour');
      expect(sent['km'], 61836);
      expect(sent['fuel'], 'quart');
      expect(sent['points'], {'pneus': 'ok', 'eclairage': 'ok', 'carrosserie': 'ok', 'documents': 'ok'});
      expect(sent['observations'], 'Dommage constaté · Avant · Rayure pare-chocs\nRoute dégradée après Tiébissou');
      expect(sent['enteredAt'], duringMission);
      expect(find.text('Fin de mission enregistrée'), findsOneWidget);

      await tapText(tester, "Retour à l'accueil");
      expect(find.byType(DriverHomeScreen), findsOneWidget);
    });

    testWidgets('flags a final odometer below the departure reading', (tester) async {
      await pumpApp(tester, location: '/missions/m-142/arrivee', now: duringMission, missions: FakeMissionsGateway(rows: inProgressRows(duringMission)));
      await enterKm(tester, const Key('arrival.odometer'), '61000');
      expect(find.text('Inférieur au kilométrage de départ (61 480 km)'), findsOneWidget);
      await tapText(tester, "Enregistrer l'arrivée");
      expect(find.text('Le kilométrage final ne peut pas être inférieur à celui du départ.'), findsOneWidget);
      expect(find.byType(EndCheckScreen), findsNothing);
    });

    testWidgets('warns on a distance beyond 1 500 km a day since the departure (bug 19/11/2026)', (tester) async {
      await pumpApp(tester, location: '/missions/m-142/arrivee', now: duringMission, missions: FakeMissionsGateway(rows: inProgressRows(duringMission)));
      await enterKm(tester, const Key('arrival.odometer'), '63000');
      expect(find.text('Écart inhabituel : 1 520 km depuis le départ (61 480 km). Vérifiez le compteur.'), findsOneWidget);
      expect(find.textContaining('Cohérent'), findsNothing);
    });
  });
}
