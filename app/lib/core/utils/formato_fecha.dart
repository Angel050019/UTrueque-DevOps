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
