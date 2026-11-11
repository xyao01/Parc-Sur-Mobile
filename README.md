# ParcSûr — application mobile

Application mobile ParcSûr (profils **demandeur** et **chauffeur**), en Flutter.

Les écrans reproduisent les maquettes du canevas Claude Design « Gestion Parc Auto – Noms et logos », page **Maquettes**, rangée « ParcSûr — application mobile » :

| Maquette | Route | Fichier |
|---|---|---|
| Mobile · Connexion | `/connexion` | `lib/features/auth/presentation/login_screen.dart` |
| Mobile · Mes missions (chauffeur) | `/missions` | `lib/features/missions/presentation/missions_screen.dart` |
| Mobile · Contrôle de départ (chauffeur) | `/missions/:id/controle-depart` | `lib/features/missions/presentation/departure_check_screen.dart` |
| Mobile · Nouvelle demande (demandeur) | `/demandes/nouvelle` | `lib/features/requests/presentation/new_request_screen.dart` |
| Modale sous 600 px (feuille basse) | composant | `lib/core/widgets/parc_bottom_sheet.dart` (`showParcBottomSheet`) |

## Lancer

```bash
cp .env.example .env              # puis renseigner l'URL Supabase et la clé publique
flutter pub get
flutter run
flutter test
```

## Design system

- Couleurs : `lib/core/theme/parcsur_colors.dart` (valeurs reprises telles quelles de la maquette).
- Typographie : Manrope (police variable embarquée, `assets/fonts/`, licence OFL), via `parcText()`.
- Icônes et logo : tracés SVG copiés de la maquette (`parc_icon.dart`, `parcsur_logo.dart`).

## Points ouverts (paramètres configurables, à trancher)

Ces règles ne sont pas décidées dans les maquettes : elles sont isolées dans des paramètres et ne sont pas codées en dur.

| Sujet | Valeur actuelle | Où la changer |
|---|---|---|
| Accueil d'un utilisateur à la fois chauffeur et demandeur | missions (chauffeur) | `lib/core/app_role.dart` (`AuthConfig.preferredRole`) |
| Compte sans rôle mobile | connexion refusée avec message | `lib/features/auth/domain/auth_service.dart` |
| Messages « identifiants incorrects », « compte non activé », « réseau » | rédigés hors maquette | `lib/features/auth/domain/login_failure.dart` |
| Nombre minimal / maximal de passagers | 1 / sans limite | `lib/features/requests/domain/request_config.dart` |
| « Besoin d'un chauffeur » par défaut | activé | `request_config.dart` |
| Niveaux de carburant, liste de contrôle du véhicule | valeurs de la maquette | `lib/features/missions/domain/departure_check_config.dart` |
| Indicateur d'étapes du contrôle de départ | étape 2 sur 3 (les étapes 1 et 3 ne sont pas maquettées) | `departure_check_config.dart` |

## Non encore branché

- Reprise de session au redémarrage : il faut se reconnecter à chaque lancement.
- Données : les missions sont des données de démonstration (seuls le nom et le rôle viennent de Supabase) (`missions_providers.dart`), placées par rapport à la date du jour.
- Envoi de « Valider le départ » et de « Envoyer la demande » vers le serveur.
- Détection hors connexion (`isOfflineProvider` vaut toujours `false`) et file d'envoi différé.
- Empreinte digitale, prise de photo, « Mot de passe oublié ? ».
- Écrans non maquettés : onglets Planning, Alertes, Profil, Accueil ; « Saisir un plein » ; « Signaler un incident ».
- États non maquettés : erreurs de saisie, interrupteur désactivé (gris provisoire `#93A3B8`), relevé kilométrique inférieur au précédent (message rouge provisoire).
