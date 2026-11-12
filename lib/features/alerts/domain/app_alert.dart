/// Who an alert was sent to: the driver account (`chauffeur_id`) or the web account (`utilisateur_id`).
enum AlertAudience { driver, requester }

/// Icon family of an alert (Mob-C12): mission (blue), reminder (orange), deadline or anomaly (red).
enum AlertKind { mission, reminder, warning }

/// A row of `notification`, from `mes_notifications_chauffeur()` or the table itself.
class AppAlert {
  const AppAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.audience,
    this.link,
    this.readAt,
  });

  /// Common shape: `id`, `titre`, `message`, `lien`, `creeLe`, `lueLe`.
  factory AppAlert.fromJson(Map<String, dynamic> json, AlertAudience audience) {
    DateTime? date(String key) => json[key] is String ? DateTime.parse(json[key] as String).toLocal() : null;
    return AppAlert(
      id: json['id'] as String,
      title: (json['titre'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      link: json['lien'] as String?,
      createdAt: date('creeLe') ?? DateTime.fromMillisecondsSinceEpoch(0),
      readAt: date('lueLe'),
      audience: audience,
    );
  }

  final String id;
  final String title;
  final String message;
  final String? link;
  final DateTime createdAt;
  final DateTime? readAt;
  final AlertAudience audience;

  bool get unread => readAt == null;

  /// Derived from the titles written by the database (« Rappel : mission… », « Échéance… »,
  /// « Kilométrage à vérifier… », « Anomalie au contrôle… »).
  AlertKind get kind {
    final t = title.toLowerCase();
    if (t.startsWith('rappel')) return AlertKind.reminder;
    if (t.contains('échéance') || t.contains('kilométrage') || t.contains('anomalie') || t.contains('incohérent')) {
      return AlertKind.warning;
    }
    return AlertKind.mission;
  }

  AppAlert markedRead(DateTime at) => AppAlert(
        id: id,
        title: title,
        message: message,
        link: link,
        createdAt: createdAt,
        readAt: at,
        audience: audience,
      );
}
