/// Nombres de los meses en español (sin depender de paquetes de idioma).
const List<String> _meses = <String>[
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

/// Convierte una fecha en texto para mostrarla: `13 de octubre de 2026`.
/// Usa la hora local del celular.
String formatearFecha(DateTime fecha) {
  final DateTime local = fecha.toLocal();
  return '${local.day} de ${_meses[local.month - 1]} de ${local.year}';
}

/// HU-07: hora corta para el chat: `09:05`. Usa la hora local del celular.
String formatearHora(DateTime fecha) {
  final DateTime local = fecha.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// HU-07: fecha corta para la bandeja de mensajes, comparada con [ahora]:
/// la hora si es de hoy (`09:05`), `Ayer`, o el día y el mes (`5 nov`).
String formatearMomento(DateTime fecha, {DateTime? ahora}) {
  final DateTime local = fecha.toLocal();
  final DateTime hoy = (ahora ?? DateTime.now()).toLocal();
  final DateTime diaFecha = DateTime(local.year, local.month, local.day);
  final DateTime diaHoy = DateTime(hoy.year, hoy.month, hoy.day);
  final int dias = diaHoy.difference(diaFecha).inDays;
  if (dias <= 0) return formatearHora(local);
  if (dias == 1) return 'Ayer';
  final String mes = _meses[local.month - 1].substring(0, 3);
  return local.year == hoy.year ? '${local.day} $mes' : '${local.day} $mes ${local.year}';
}
