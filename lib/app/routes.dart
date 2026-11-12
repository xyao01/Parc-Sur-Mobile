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

  static const planning = '/planning'; // Mob-C11 Planning chauffeur

  static const newRequest = '/demandes/nouvelle';
  static const profile = '/profil';
}
