/// Horario permitido para un encuentro (HU-08, Escenario 6). La base de
/// datos aplica la misma regla (`encuentro_horario_valido`).
///
/// - De lunes a viernes, de 7:00 a 20:00, en horas exactas o medias horas.
/// - Desde 30 minutos después de ahora y hasta 14 días adelante.
/// - Siempre con la hora del centro de México (la de la universidad), no la
///   del celular: así un celular con otra zona horaria ve los mismos horarios.
///
/// Las fechas que regresa son instantes en UTC; para mostrarlas se usa
/// [formatear] o [formatearDia].
class HorarioEncuentro {
  const HorarioEncuentro();

  static const int horaInicio = 7;
  static const int horaFin = 20;
  static const int minutosEntreHorarios = 30;
  static const Duration anticipacionMinima = Duration(minutes: 30);
  static const Duration anticipacionMaxima = Duration(days: 14);

  /// El centro de México no cambia de horario desde 2022: siempre UTC-6.
  static const Duration _desfaseMexico = Duration(hours: -6);

  static const List<String> _dias = <String>['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
  static const List<String> _meses = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// La hora "de reloj" en la universidad. El resultado tiene la bandera de
  /// UTC, pero sus campos (día, hora…) son los del centro de México.
  static DateTime enMexico(DateTime instante) => instante.toUtc().add(_desfaseMexico);

  /// El instante en que en la universidad es [dia] a las [hora]:[minuto].
  static DateTime instante(DateTime dia, int hora, int minuto) =>
      DateTime.utc(dia.year, dia.month, dia.day, hora, minuto).subtract(_desfaseMexico);

  /// ¿Se puede proponer un encuentro en [fechaHora]?
  bool esValido(DateTime? fechaHora, {required DateTime ahora}) {
    if (fechaHora == null) return false;
    if (fechaHora.isBefore(ahora.add(anticipacionMinima))) return false;
    if (fechaHora.isAfter(ahora.add(anticipacionMaxima))) return false;
    final DateTime local = enMexico(fechaHora);
    if (local.weekday > DateTime.friday) return false;
    if (local.second != 0 || local.millisecond != 0 || local.microsecond != 0) return false;
    if (local.minute % minutosEntreHorarios != 0) return false;
    final int minutosDelDia = local.hour * 60 + local.minute;
    return minutosDelDia >= horaInicio * 60 && minutosDelDia <= horaFin * 60;
  }

  /// Los días (lunes a viernes) que todavía tienen algún horario, del más
  /// próximo al más lejano. Cada día es una fecha UTC a medianoche con el
  /// día del calendario de la universidad.
  List<DateTime> diasDisponibles({required DateTime ahora}) {
    final DateTime hoy = enMexico(ahora);
    final List<DateTime> dias = <DateTime>[];
    for (int i = 0; i <= anticipacionMaxima.inDays; i++) {
      final DateTime dia = DateTime.utc(hoy.year, hoy.month, hoy.day + i);
      if (horasDisponibles(dia, ahora: ahora).isNotEmpty) dias.add(dia);
    }
    return List.unmodifiable(dias);
  }

  /// Los horarios permitidos de [dia], del más temprano al más tarde.
  List<DateTime> horasDisponibles(DateTime dia, {required DateTime ahora}) {
    final List<DateTime> horas = <DateTime>[];
    for (int minutos = horaInicio * 60; minutos <= horaFin * 60; minutos += minutosEntreHorarios) {
      final DateTime t = instante(dia, minutos ~/ 60, minutos % 60);
      if (esValido(t, ahora: ahora)) horas.add(t);
    }
    return List.unmodifiable(horas);
  }

  /// "jueves 12 de noviembre, 13:00" (hora de la universidad).
  static String formatear(DateTime fechaHora) {
    final DateTime l = enMexico(fechaHora);
    return '${formatearDia(l)}, ${formatearHora(fechaHora)}';
  }

  /// "jueves 12 de noviembre" para un día de [diasDisponibles] (o un
  /// instante ya pasado por [enMexico]).
  static String formatearDia(DateTime dia) => '${_dias[dia.weekday - 1]} ${dia.day} de ${_meses[dia.month - 1]}';

  /// "jue 12" para los botones de día.
  static String formatearDiaCorto(DateTime dia) => '${_dias[dia.weekday - 1].substring(0, 3)} ${dia.day}';

  /// "13:00" (hora de la universidad).
  static String formatearHora(DateTime fechaHora) {
    final DateTime l = enMexico(fechaHora);
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}
