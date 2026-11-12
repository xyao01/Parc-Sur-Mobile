# ParcSûr — application mobile

Application mobile ParcSûr (profils **demandeur** et **chauffeur**), en Flutter, branchée sur le projet Supabase `parc_sur`.

Les écrans reproduisent les maquettes du canevas Claude Design « Gestion Parc Auto – Noms et logos », page **Maquettes**, rangée « ParcSûr — application mobile » :

| Écran | Route | Source du design | Fichier |
|---|---|---|---|
| Connexion | `/connexion` | Mobile · Connexion | `lib/features/auth/presentation/login_screen.dart` |
| Mot de passe oublié | `/mot-de-passe-oublie` | contenu de la maquette web « Mot de passe oublié et politique » (§ 1-2), mise en page de Mobile · Connexion | `lib/features/auth/presentation/forgot_password_screen.dart` |
| Réinitialisation (lien reçu par e-mail) | `/reinitialiser-mot-de-passe` | maquette web (§ 3 et « Lien expiré »), mise en page de Mobile · Connexion | `lib/features/auth/presentation/reset_password_screen.dart` |
| Nouveau mot de passe (première connexion) | `/premiere-connexion` | contenu de la maquette web « Mot de passe oublié et politique » (§ 3), mise en page de Mobile · Connexion | `lib/features/auth/presentation/new_password_screen.dart` |
| Mes missions (chauffeur) | `/missions` | Mobile · Mes missions | `lib/features/missions/presentation/missions_screen.dart` |
| Contrôle de départ (chauffeur) | `/missions/:id/controle-depart` | Mobile · Contrôle de départ | `lib/features/missions/presentation/departure_check_screen.dart` |
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
| Contrôle de départ | `rpc/enregistrer_controle` (id client : un renvoi n'est pas compté deux fois) | chauffeur |
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
| Case de contrôle non cochée | envoyée comme `anomalie` (le serveur notifie alors les gestionnaires) | `departure_check_config.dart` (`uncheckedValue`) |
| Niveaux de carburant | 1/4, 1/2, 3/4, Plein (la base accepte aussi `vide`, non proposé par la maquette) | `departure_check_config.dart` |
| Liste de contrôle | 4 points de la maquette → `pneus`, `eclairage`, `carrosserie`, `documents` (la base en connaît 8) | `departure_check_config.dart` |
| Indicateur d'étapes du contrôle de départ | étape 2 sur 3 (les étapes 1 et 3 ne sont pas maquettées) | `departure_check_config.dart` |
| Nombre minimal / maximal de passagers | 1 / sans limite | `lib/features/requests/domain/request_config.dart` |

## Écarts avec la maquette imposés par les données

- La carte « Mission du jour » n'affiche que la destination : la base n'a pas de ville de départ.
- L'aide du kilométrage n'affiche pas la date du dernier relevé : `mes_missions_chauffeur()` ne la renvoie pas.

## Non encore branché

- « Envoyer la demande » (demandeur) vers le serveur.
- Contrôle de retour (non maquetté) : la carte n'a plus d'action une fois le départ enregistré.
- Reprise de session au redémarrage : il faut se reconnecter à chaque lancement.
- Détection hors connexion (`isOfflineProvider` vaut toujours `false`) et file d'envoi différé.
- Empreinte digitale, prise de photo.
- Écrans « Mot de passe oublié » et « Réinitialisation » : pas de maquette mobile ; textes repris du web, composés uniquement de composants existants. À faire valider dans Claude Design.
- Écrans non maquettés : onglets Planning, Alertes, Accueil ; « Saisir un plein » ; « Signaler un incident ».
- États non maquettés : chargement et erreur de la liste des missions, « Aucune mission aujourd'hui », interrupteur désactivé (gris provisoire `#93A3B8`), relevé kilométrique inférieur au précédent (message rouge provisoire).
