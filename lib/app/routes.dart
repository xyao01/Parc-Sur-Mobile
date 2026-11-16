/// Route paths of the mobile app.
abstract final class Routes {
  static const login = '/connexion';
  static const newPassword = '/premiere-connexion';
  static const forgotPassword = '/mot-de-passe-oublie';
  static const resetPassword = '/reinitialiser-mot-de-passe';

  /// Pages open to a signed-out user.
  static const public = {login, forgotPassword, resetPassword};

  /// Driver journey Mob-C01…C10.
  static const missions = '/missions'; // C01 Accueil chauffeur
  static String requestNotice(String id) => '/missions/demandes/$id'; // C02
  static String requestDetails(String id) => '/missions/demandes/$id/details'; // C03
  static String requestResponse(String id, {required bool accept}) =>
      '/missions/demandes/$id/reponse?choix=${accept ? 'accepter' : 'refuser'}'; // C04
  static String departurePreparation(String id) => '/missions/$id/preparation'; // C05
  static String departureValidation(String id) => '/missions/$id/validation'; // C06
  static String inProgress(String id) => '/missions/$id/en-cours'; // C07
  static String arrival(String id) => '/missions/$id/arrivee'; // C08
  static String endCheck(String id) => '/missions/$id/controle-fin'; // C09
  static String closure(String id) => '/missions/$id/cloture'; // C10
  static String fuelEntry(String id) => '/missions/$id/plein'; // C13

  /// « Page en maintenance » (`?vue=` name of the view).
  static const maintenance = '/maintenance';

  static const planning = '/planning'; // Mob-C11 Planning chauffeur
  static const alerts = '/alertes'; // Mob-C12 Alertes (chauffeur et demandeur)

  /// Requester journey Mob-D01…D10.
  static const requesterHome = '/demandes'; // D01
  static const newRequest = '/demandes/nouvelle'; // D02
  static const newRequestSummary = '/demandes/nouvelle/recapitulatif'; // D03
  static String editRequest(String id) => '/demandes/$id/modifier'; // D02 (edit)
  static String editRequestSummary(String id) => '/demandes/$id/modifier/recapitulatif'; // D03 (edit)
  static String requestSent(String id) => '/demandes/$id/envoyee'; // D04
  static const myRequests = '/mes-demandes'; // D05
  static String monthlyReading(String vehicleId) => '/mon-vehicule/$vehicleId/releve'; // D11 (l2-km-02)
  static String requestDetail(String id) => '/demandes/$id'; // D06
  static String requestDecision(String id) => '/demandes/$id/decision'; // D07
  static String requestTracking(String id) => '/demandes/$id/suivi'; // D08
  static String requestEnd(String id) => '/demandes/$id/fin'; // D09
  static String requestRating(String id) => '/demandes/$id/evaluation'; // D10
  static const profile = '/profil';
  static const changePassword = '/profil/mot-de-passe';
}
