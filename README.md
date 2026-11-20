# ParcSûr — application mobile

Application mobile ParcSûr (profils **demandeur** et **chauffeur**), en Flutter, branchée sur le projet Supabase `parc_sur`.

Les écrans reproduisent les maquettes du canevas Claude Design « Gestion Parc Auto – Noms et logos », page **Maquettes**, rangée « ParcSûr — application mobile » :

| Écran | Route | Source du design | Fichier |
|---|---|---|---|
| Connexion | `/connexion` | Mobile · Connexion | `lib/features/auth/presentation/login_screen.dart` |
| Mot de passe oublié | `/mot-de-passe-oublie` | contenu de la maquette web « Mot de passe oublié et politique » (§ 1-2), mise en page de Mobile · Connexion | `lib/features/auth/presentation/forgot_password_screen.dart` |
| Réinitialisation (lien reçu par e-mail) | `/reinitialiser-mot-de-passe` | maquette web (§ 3 et « Lien expiré »), mise en page de Mobile · Connexion | `lib/features/auth/presentation/reset_password_screen.dart` |
| Nouveau mot de passe (première connexion) | `/premiere-connexion` | contenu de la maquette web « Mot de passe oublié et politique » (§ 3), mise en page de Mobile · Connexion | `lib/features/auth/presentation/new_password_screen.dart` |
| Chauffeur · 1 · Accueil | `/missions` | Mob-C01 (remplace « Mobile · Mes missions ») | `lib/features/missions/presentation/driver_home_screen.dart` |
| Chauffeur · 2 · Nouvelle demande reçue | `/missions/demandes/:id` | Mob-C02 | `new_request_notice_screen.dart` |
| Chauffeur · 3 · Détails de la mission | `/missions/demandes/:id/details` | Mob-C03 | `mission_details_screen.dart` |
| Chauffeur · 4 · Acceptation ou refus | `/missions/demandes/:id/reponse?choix=accepter\|refuser` | Mob-C04 | `request_response_screen.dart` |
| Chauffeur · 5 · Préparation du départ | `/missions/:id/preparation` | Mob-C05 (remplace « Mobile · Contrôle de départ ») | `departure_preparation_screen.dart` |
| Chauffeur · 6 · Validation du départ | `/missions/:id/validation` | Mob-C06 | `departure_validation_screen.dart` |
| Chauffeur · 7 · Mission en cours | `/missions/:id/en-cours` | Mob-C07 | `mission_in_progress_screen.dart` |
| Chauffeur · 8 · Arrivée à destination | `/missions/:id/arrivee` | Mob-C08 | `arrival_screen.dart` |
| Chauffeur · 9 · Contrôle de fin de mission | `/missions/:id/controle-fin` | Mob-C09 | `end_check_screen.dart` |
| Chauffeur · 10 · Clôture de la demande | `/missions/:id/cloture` | Mob-C10 | `closure_screen.dart` |
| Chauffeur · Planning | `/planning` | Mob-C11 (maquette proposée puis validée) | `planning_screen.dart` |
| Alertes (chauffeur et demandeur) | `/alertes` | Mob-C12 (maquette proposée puis validée) | `lib/features/alerts/presentation/alerts_screen.dart` |
| Demandeur · 1 · Accueil | `/demandes` | Mob-D01 | `lib/features/requests/presentation/requester_home_screen.dart` |
| Demandeur · 2 · Formulaire (création et modification) | `/demandes/nouvelle`, `/demandes/:id/modifier` | Mob-D02 (remplace « Mobile · Nouvelle demande ») | `request_form_screen.dart` |
| Demandeur · 3 · Récapitulatif | `…/recapitulatif` | Mob-D03 | `request_summary_screen.dart` |
| Demandeur · 4 · Demande envoyée | `/demandes/:id/envoyee` | Mob-D04 | `request_sent_screen.dart` |
| Demandeur · 5 · Mes demandes | `/mes-demandes` | Mob-D05 | `my_requests_screen.dart` |
| Demandeur · 6 · Détail et annulation | `/demandes/:id` | Mob-D06 | `request_detail_screen.dart` |
| Demandeur · 7 · Décision | `/demandes/:id/decision` | Mob-D07 | `request_decision_screen.dart` |
| Demandeur · 8 · Suivi de la mission | `/demandes/:id/suivi` | Mob-D08 | `request_tracking_screen.dart` |
| Demandeur · 9 · Fin de mission | `/demandes/:id/fin` | Mob-D09 | `request_end_screen.dart` |
| Demandeur · 10 · Évaluation | `/demandes/:id/evaluation` | Mob-D10 | `request_rating_screen.dart` |
| Profil (espace, coordonnées, mot de passe, déconnexion) | `/profil`, `/profil/mot-de-passe` | Mob-P01 (maquette proposée puis validée) | `lib/features/profile/presentation/profile_screen.dart` |
| Page en maintenance (vues sans backend) | `/maintenance?vue=…` | Mob-X01 | `lib/core/widgets/maintenance_screen.dart` |
| Agent · Relevé mensuel du véhicule affecté | `/mon-vehicule/:id/releve` | Mob-D11 (proposée, à valider) | `lib/features/vehicle/presentation/monthly_reading_screen.dart` |
| Feuille basse (modale < 600 px) | composant | Modale sous 600 px | `lib/core/widgets/parc_bottom_sheet.dart` |

## Lancer

```bash
cp .env.example .env              # puis renseigner l'URL Supabase et la clé publique
flutter pub get
flutter run
flutter test
```

## Backend Supabase utilisé

| Usage | Appel | Droit exigé par l'API (`droit_endpoint`) |
|---|---|---|
| Compte bloqué ? | `rpc/blocage_connexion` | anonyme |
| Échec de connexion | `rpc/echec_connexion` | anonyme |
| Connexion | Supabase Auth `signInWithPassword` | — |
| Profil mobile (nom, rôles) | `rpc/profil_mobile` | authentifié |
| Connexion réussie | `rpc/connexion_reussie` | chauffeur ou connecté |
| Journal d'audit (demandeurs) | `rpc/journaliser_session` | connecté |
| Mot de passe oublié | Supabase Auth `resetPasswordForEmail` (e-mail construit par la fonction `auth-email-hook`, envoyé par n8n) | — |
| Lien de réinitialisation | lien profond `com.syabetech.parcsur://reinitialiser-mot-de-passe` : supabase_flutter ouvre la session de récupération (PKCE) | — |
| Nouveau mot de passe | Supabase Auth `updateUser` (retire `mot_de_passe_provisoire` et `mot_de_passe_par_defaut`, comme l'application web) | — |
| Missions du chauffeur | `rpc/mes_missions_chauffeur` | chauffeur |
| Validation du départ (C06) | `rpc/enregistrer_controle`, type `depart` (id client : un renvoi n'est pas compté deux fois) | chauffeur |
| Clôture (C10) : arrivée, contrôle de fin, observations | `rpc/enregistrer_controle`, type `retour`, saisi à l'heure d'arrivée ; la demande est ensuite clôturée par le gestionnaire (`cloturer_mission` n'est pas ouvert aux chauffeurs) | chauffeur |
| Réponse à une demande (C02-C04), disponibilité (C01), incident (C07), départ bloqué (C06) | **aucun appel : pas d'équivalent en base**. L'application affiche « Cette action n'est pas encore disponible sur le serveur » ; aucune demande « à répondre » n'apparaît | — |
| Alertes du chauffeur | `rpc/mes_notifications_chauffeur`, `rpc/marquer_notifications_chauffeur_lues` (migration `20261112110000_notifications_chauffeur_mobile.sql` du dépôt backend) | chauffeur |
| Alertes du demandeur | table `notification` : lecture et `lue_le` (RLS : alertes du compte web connecté) | connecté |
| Demandes du demandeur (D01, D05-D09) | `demande_vue` filtrée sur `demandeur_id = utilisateur_courant()` (un gestionnaire voit sinon toutes les demandes) | Demandes › Saisie › consulter |
| Nouvelle demande (D03) | insertion dans `demande_vehicule` (contrôles du déclencheur `controler_demande`) | Demandes › Saisie › ajouter |
| Modification (D02-D03) | mise à jour de `demande_vehicule`, demande en attente uniquement (RLS) | Demandes › Saisie › modifier |
| Annulation (D06) | `rpc/annuler_demande` | Demandes › Saisie › modifier |
| Signaler un problème (D08), évaluation (D10) | **aucun appel : pas d'équivalent en base** ; l'application affiche « pas encore disponible » | — |
| Déconnexion | Supabase Auth `signOut` | — |
| Relevé mensuel (agent, l2-km-02) | `rpc/mon_vehicule`, `rpc/saisir_releve_mensuel` (version avec `p_id_client` : un renvoi n'est pas compté deux fois) | connecté |
| Reprise de session au lancement | session gardée par Supabase + `rpc/profil_mobile` (sans nouvelle « connexion réussie ») | authentifié |
| Profil : coordonnées du demandeur | lecture de sa ligne `utilisateur` (RLS) ; enregistrement par `rpc/modifier_mon_compte` | connecté |
| Profil : changer le mot de passe | Supabase Auth `updateUser` (même politique que la première connexion) | — |

Politique de mot de passe identique au web : 8 caractères minimum, dont une majuscule et un chiffre.

### Réinitialisation du mot de passe : réglage Supabase à faire

Ajouter `com.syabetech.parcsur://reinitialiser-mot-de-passe` dans Supabase › Authentication › URL Configuration › **Redirect URLs**. Sans cela, Supabase renvoie le lien de l'e-mail vers le Site URL (application web) et l'application mobile ne s'ouvre pas.

Le lien doit être ouvert sur le téléphone qui a fait la demande (flux PKCE : le code de vérification reste sur l'appareil).

## Design system

- Couleurs : `lib/core/theme/parcsur_colors.dart` (valeurs reprises telles quelles de la maquette).
- Typographie : Manrope (police variable embarquée, `assets/fonts/`, licence OFL), via `parcText()`.
- Icônes et logo : tracés SVG copiés de la maquette (`parc_icon.dart`, `parcsur_logo.dart`).

## Points ouverts (paramètres configurables, à trancher)

| Sujet | Valeur actuelle | Où la changer |
|---|---|---|
| Accueil d'un utilisateur à la fois chauffeur et demandeur | missions (chauffeur) ; il n'a alors pas d'onglet vers « Nouvelle demande » | `lib/core/app_role.dart` (`AuthConfig.preferredRole`) |
| Compte sans rôle mobile | connexion refusée avec message | `lib/features/auth/domain/auth_service.dart` |
| Messages « compte non activé », « réseau » | rédigés hors maquette | `lib/features/auth/domain/login_failure.dart` |
| Retour du lien de réinitialisation | application mobile (lien profond) ; modifiable par `passwordResetRedirect` dans `.env` (par exemple vers la page web `/reinitialiser-mot-de-passe`) | `lib/core/app_role.dart` (`AuthConfig.passwordResetRedirect`) |
| Durée de validité affichée du lien | 1 heure (comme le web ; la durée réelle se règle dans Supabase Auth) | `AuthConfig.resetLinkValidityHours` |
| Case de contrôle non cochée | envoyée comme `anomalie` (le serveur notifie alors les gestionnaires) | `mission_flow_config.dart` (`uncheckedValue`) |
| Niveaux de carburant | 1/4, 1/2, 3/4, Plein (la base accepte aussi `vide`, non proposé par la maquette) | `mission_flow_config.dart` |
| Liste de départ (C05) | 5 lignes → `pneus`, `eclairage`, `documents`, `carrosserie`, et « Propreté et équipements » → `proprete` + `equipements` (la base n'a pas `freins` ni `niveaux` dans la maquette) | `mission_flow_config.dart` |
| Liste de retour (C09) | 4 lignes → `pneus`, `eclairage`, `carrosserie`, « Documents et clés restitués » → `documents` | `mission_flow_config.dart` |
| Dommage signalé (C09) | envoyé dans `p_observations` (« Dommage constaté · zone · description »), avant les observations de C10 | `mission_drafts.dart` |
| Plafond de kilométrage (C05, C08, C13) | 1 500 km par jour entamé (au moins 1 jour, depuis le contrôle de départ ; 1 jour depuis le dernier relevé, dont la date n'est pas renvoyée), comme `seuil_km_par_jour()` en base. Au-delà : « Écart inhabituel … Vérifiez le compteur. » en rouge, sans bloquer l'envoi (la base enregistre et marque le relevé « à vérifier ») | `mission_flow_config.dart` (`maxKmPerDay`) |
| Rechargement au retour dans l'application | demandes, missions, demandes à répondre et alertes rechargées dès que l'application revient au premier plan | `lib/app/app.dart` (`_reloadSharedData`) |
| Carte « Je suis disponible » (C01) | masquée sur l'accueil chauffeur (demande du 20/11/2026) ; la disponibilité reste gérée par la base et le web | `lib/core/features.dart` (`availabilityCard`) |
| Statut du véhicule pendant la mission | « en mission » au contrôle de départ, « disponible » au contrôle de retour, à la clôture ou à l'annulation ; un véhicule immobilisé ou en maintenance garde son statut | base : `vehicule_en_mission_automatique()` (migration `20261120110000_mission_chauffeur_vehicule`, `false` = statut inchangé) |
| Récapitulatif de clôture (C10) | pleins (nombre, litres et montant cumulés) et incidents (natures) envoyés au serveur ; un plein ou un incident gardé sur le téléphone sans réseau n'y figure qu'après son envoi. « — » tant que la migration `20261120110000` n'est pas appliquée | `closure_screen.dart` |
| Motifs de refus, natures de problème, types d'incident, zones de dommage | listes de la maquette | `mission_flow_config.dart` |
| Message des actions sans backend | « Cette action n'est pas encore disponible sur le serveur. Prévenez votre gestionnaire de parc. » (hors maquette) | `mission_flow_config.dart` (`unavailableMessage`) |
| Nombre minimal / maximal de passagers | 1 / 50 (comme la base et le web) | `lib/features/requests/domain/request_config.dart` |
| Motif d'annulation (D06, la maquette n'en demande pas ; `annuler_demande` l'exige) | « Annulée par le demandeur depuis l'application mobile. » | `RequestConfig.cancelReason` |
| États affichés d'une demande | En attente, Validée (avant le départ), En cours (entre départ et retour prévus), Terminée (retour passé, règle du web), Refusée, Annulée | `vehicle_request.dart` (`stateAt`) |
| Types de problème (D08), critères d'évaluation (D10) | listes de la maquette | `RequestConfig` |

## Écarts avec la maquette imposés par les données

- Trajets « Abidjan → Bouaké » : la base n'a pas de ville de départ, seule la destination est affichée (C01, C03, C04, C07, C10).
- L'aide du kilométrage n'affiche pas la date du dernier relevé : `mes_missions_chauffeur()` ne la renvoie pas.
- C01 : « Chauffeur · Parc central » devient « Chauffeur » (parc non renvoyé par `profil_mobile()`).
- C03 : badge « Disponible » du véhicule et direction du demandeur absents (non renvoyés).
- C07 : pas de position GPS ; la barre de progression suit le temps écoulé entre le départ et le retour prévu, et « Arrivée prévue » devient « Retour prévu ».
- C09 / C10 : le niveau de carburant du départ n'est pas renvoyé ; « (départ : 3/4) » et « 3/4 → 1/4 » n'affichent que l'arrivée.
- C06 : la ligne « Pneus, feux, documents : Conformes » devient « Vérification du véhicule : Conformes / N anomalie(s) : … » (5 points contrôlés).
- C10 : l'écran final dit « Fin de mission enregistrée » au lieu de « Demande clôturée », car la clôture reste au gestionnaire.
- Ajout hors maquette : sur l'accueil, une mission déjà partie propose « Reprendre la mission en cours » (C07).
- « Mobile · Mes missions » (liste « À venir », « Saisir un plein ») et « Mobile · Contrôle de départ » sont remplacés par le parcours C01-C10 : les missions à venir ne sont plus listées (seulement comptées).

## Saisie hors connexion (l2-mob-04)

- Contrôles de départ et de retour, relevés mensuels : sans réseau, la saisie est gardée sur le téléphone (`shared_preferences`, conservée si l'application est fermée) avec son identifiant client, puis envoyée automatiquement au retour du réseau (au lancement et à chaque reconnexion). Le serveur ignore un second envoi du même identifiant.
- Bandeau sous l'en-tête : « Hors connexion : la saisie sera envoyée dès le retour du réseau. », « N saisies en attente d'envoi. », ou saisie refusée par le serveur (message, bouton OK).
- La dernière liste des missions et du véhicule affecté est gardée pour travailler sans réseau ; une saisie en attente est déjà prise en compte (mission « en cours », relevé du mois fait).
- Sans réseau au lancement, la session est rouverte avec le dernier profil gardé sur le téléphone.

## Non encore branché

- Côté base : réponse du chauffeur à une demande, blocage du départ (voir « Backend Supabase utilisé »).
- Vues sans backend : elles ouvrent « Page en maintenance » tant que leur interrupteur est éteint dans `lib/core/features.dart` (réponse aux demandes, disponibilité, incident, blocage du départ, photos, appels, problème signalé par le demandeur, évaluation, informations du chauffeur dans le Profil).
- Profil du chauffeur : téléphone et permis non lisibles (table `chauffeur` fermée aux chauffeurs) → « Page en maintenance ».
- Empreinte digitale, prise de photo (boutons affichés, inactifs), appel du demandeur (bouton affiché, inactif).
- Écrans « Mot de passe oublié » et « Réinitialisation » : pas de maquette mobile ; textes repris du web, composés uniquement de composants existants. À faire valider dans Claude Design.
- « Je suis disponible » (C01, décisions du 16/11/2026) : désactivé, une absence au motif « Indisponible (déclaré par le chauffeur) » commence à l'heure du clic ; réactivé, elle se termine à l'heure de la réactivation. Les heures exactes sont gardées (`debut_le`, `fin_le`), la disponibilité reste comptée en demi-journées (avant 12 h = matin). Tant qu'il n'a pas réactivé, l'absence est prolongée chaque nuit (tâche `prolonger-indisponibilites`). Refusé si une mission est attribuée au chauffeur ce jour-là. Une absence saisie par le gestionnaire ne se lève pas depuis le téléphone. Envoi en ligne seulement. **Migration `20261116110000_disponibilite_chauffeur.sql` (dépôt `parc_sur`) non appliquée** : l'interrupteur `driverAvailability` reste éteint (« Page en maintenance »).
- Plein pendant la mission (Mob-C13, validé le 16/11/2026) : bouton « Ajouter un plein » de C07. Ticket de caisse obligatoire (photo, 1 à 2), pris en compte sans validation du gestionnaire, seulement pendant la mission (après le contrôle de départ, avant le retour), kilométrage au moins égal à celui du départ. Le ticket est déposé dans `justificatifs/carburant/<id du plein>/1-ticket.jpg`, puis le plein est enregistré par `saisir_plein_chauffeur` ; sans réseau, le plein et sa photo restent sur le téléphone et partent au retour du réseau. **La migration `20261116100000_plein_chauffeur.sql` (dépôt `parc_sur`) n'est pas encore appliquée** : l'interrupteur `fuelEntry` reste éteint et le bouton ouvre « Page en maintenance » jusque-là.
- Incident pendant la mission (Mob-C07, validé le 16/11/2026) : l'incident est déclaré comme **sinistre** (nature « sinistre », véhicule et conducteur de la mission, description « [Panne] texte · mission D-xxxx »). Photos facultatives (0 à 2), déposées dans `justificatifs/sinistres/<id>/1-photo.jpg`. Tous les comptes actifs ayant le droit « Sinistres › Déclarations › Consulter » reçoivent une notification (cloche web et e-mail). Case « Incident grave » cochée par le chauffeur : le véhicule passe « immobilisé » et la mission est « interrompue » (bandeau rouge ; il ne reste que « Faire le contrôle de retour ») ; le gestionnaire remet le véhicule en service depuis le web. Sans réseau, l'incident et ses photos restent sur le téléphone (la mission s'affiche déjà interrompue) et partent au retour du réseau. Fonction `signaler_incident_chauffeur`. **Migration `20261116130000_incident_chauffeur.sql` (dépôt `parc_sur`) non appliquée** : l'interrupteur `driverIncident` reste éteint (« Page en maintenance »).
- Parcours demandeur, écarts imposés par les données : pas de ville de départ (destination seule) ; pas de direction du demandeur (D01) ; pas de lieu de prise en charge ni de téléphone du chauffeur (D07, bouton d'appel inactif) ; heures réelles de départ et d'arrivée, distance et dommages non lisibles par le demandeur (D08, D09 : horaires prévus) ; « Terminée » = retour prévu passé (la date de clôture n'est pas dans `demande_vue`). Le sélecteur « Validée / Refusée » de D07 n'existe que dans la maquette : l'application affiche la décision réelle. Avant le départ, D08 affiche « Départ … » à la place de « Mission en cours ».
- Alertes : une alerte de demande (`/mes-demandes?id=…`) ouvre la demande ; une alerte de mission du chauffeur ouvre le Planning ; les autres liens (véhicules, pages du gestionnaire) n'ont pas d'écran mobile : l'alerte est seulement marquée comme lue. Les 50 alertes les plus récentes sont chargées par compte.
- Notifications push (l2-not-01) : non faites. Il faut un projet Firebase (Cloud Messaging), ses fichiers de configuration Android/iOS, et une fonction serveur qui envoie le push à chaque notification enregistrée.
- Dépenses au contrôle de retour (l2-mis-02) : la table `depense` est réservée à la permission « Dépenses › Saisie », que les comptes chauffeur n'ont pas ; l'entrée « Dépenses engagées » de C10 ouvre « Page en maintenance ».
- iOS : schéma d'URL du lien de réinitialisation déclaré (`Info.plist`) ; compilation et test à faire sur un Mac.
- Planning : seules les missions renvoyées par `mes_missions_chauffeur()` apparaissent (départ dans les 30 jours, non clôturées) ; ni historique ni absences.
- États non maquettés : chargement et erreur des missions, « Aucune mission aujourd'hui », mission introuvable, interrupteur désactivé (gris provisoire `#93A3B8`), kilométrage inférieur au relevé précédent ou au départ (messages rouges provisoires).
