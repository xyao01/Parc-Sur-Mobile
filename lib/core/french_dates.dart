/// Minimal French date formatting matching the prototype copy
/// (avoids pulling `intl` for a handful of patterns).
abstract final class FrenchDates {
  static const _weekdays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
  static const _weekdaysShort = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const _monthsShort = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  static String _cap(String s) => s[0].toUpperCase() + s.substring(1);
  static String _pad2(int n) => n.toString().padLeft(2, '0');

  /// `07:30`
  static String time(DateTime d) => '${_pad2(d.hour)}:${_pad2(d.minute)}';

  /// `30/10`
  static String dayMonth(DateTime d) => '${_pad2(d.day)}/${_pad2(d.month)}';

  /// `mer.`
  static String weekdayShort(DateTime d) => _weekdaysShort[d.weekday - 1];

  /// `Mardi 3 novembre`
  static String longDay(DateTime d) => '${_cap(_weekdays[d.weekday - 1])} ${d.day} ${_months[d.month - 1]}';

  /// `Mer. 4 nov. · 17:00`
  static String shortDayTime(DateTime d) =>
      '${_cap(weekdayShort(d))} ${d.day} ${_monthsShort[d.month - 1]} · ${time(d)}';

  /// `84 112` – thousands separated by a space.
  static String km(int value) {
    final s = value.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
