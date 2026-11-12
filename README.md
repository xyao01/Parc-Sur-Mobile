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
| Nouvelle demande (demandeur) | `/demandes/nouvelle` | Mobile · Nouvelle demande | `lib/features/requests/presentation/new_request_screen.dart` |
| Profil et déconnexion | `/profil` | **non maquetté** : composé de composants existants | `lib/features/profile/presentation/profile_screen.dart` |
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
| Déconnexion | Supabase Auth `signOut` | — |

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
| Motifs de refus, natures de problème, types d'incident, zones de dommage | listes de la maquette | `mission_flow_config.dart` |
| Message des actions sans backend | « Cette action n'est pas encore disponible sur le serveur. Prévenez votre gestionnaire de parc. » (hors maquette) | `mission_flow_config.dart` (`unavailableMessage`) |
| Nombre minimal / maximal de passagers | 1 / sans limite | `lib/features/requests/domain/request_config.dart` |

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

## Non encore branché

- « Envoyer la demande » (demandeur) vers le serveur.
- Côté base : réponse du chauffeur à une demande, disponibilité, incidents, blocage du départ (voir « Backend Supabase utilisé »).
- Reprise de session au redémarrage : il faut se reconnecter à chaque lancement.
- Détection hors connexion (`isOfflineProvider` vaut toujours `false`) et file d'envoi différé.
- Empreinte digitale, prise de photo (boutons affichés, inactifs), appel du demandeur (bouton affiché, inactif).
- Écrans « Mot de passe oublié » et « Réinitialisation » : pas de maquette mobile ; textes repris du web, composés uniquement de composants existants. À faire valider dans Claude Design.
- Écrans non maquettés : onglet Accueil du demandeur ; « Saisir un plein ».
- Alertes : toucher une alerte la marque comme lue mais n'ouvre pas d'écran. Les liens enregistrés visent l'application web (`/mes-demandes`, `/demandes`, `/vehicules/…`) et n'ont pas encore d'équivalent mobile. Les 50 alertes les plus récentes sont chargées par compte.
- Planning : seules les missions renvoyées par `mes_missions_chauffeur()` apparaissent (départ dans les 30 jours, non clôturées) ; ni historique ni absences.
- États non maquettés : chargement et erreur des missions, « Aucune mission aujourd'hui », mission introuvable, interrupteur désactivé (gris provisoire `#93A3B8`), kilométrage inférieur au relevé précédent ou au départ (messages rouges provisoires).
