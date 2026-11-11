/// Route paths of the mobile app.
abstract final class Routes {
  static const login = '/connexion';
  static const newPassword = '/premiere-connexion';
  static const missions = '/missions';
  static String departureCheck(String missionId) => '/missions/$missionId/controle-depart';
  static const newRequest = '/demandes/nouvelle';
  static const profile = '/profil';
}
