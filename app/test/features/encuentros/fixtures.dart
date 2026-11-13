import 'package:mocktail/mocktail.dart';
import 'package:utrueque/features/encuentros/domain/entities/encuentro.dart';
import 'package:utrueque/features/encuentros/domain/entities/punto_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/repositories/encuentros_repository.dart';

import '../chat/fixtures.dart';

export '../chat/fixtures.dart';

class MockEncuentrosRepository extends Mock implements EncuentrosRepository {}

/// "Ahora" en casi todas las pruebas: miércoles 11 de noviembre de 2026 a
/// las 10:00 en la universidad (16:00 UTC).
final DateTime ahora = DateTime.utc(2026, 11, 11, 16, 0);
DateTime reloj() => ahora;

/// Jueves 12 de noviembre a las 13:00 en la universidad (19:00 UTC).
final DateTime jueves13 = DateTime.utc(2026, 11, 12, 19, 0);

/// Sábado 14 de noviembre a las 10:00 en la universidad.
final DateTime sabado10 = DateTime.utc(2026, 11, 14, 16, 0);

const PuntoEncuentro biblioteca = PuntoEncuentro(
  id: 'biblioteca',
  nombre: 'Biblioteca - Entrada Principal',
  referencia: 'Frente a la puerta principal de la biblioteca',
);

const PuntoEncuentro cafeteria = PuntoEncuentro(
  id: 'cafeteria',
  nombre: 'Cafetería - Área de mesas',
  referencia: 'Mesas junto a la barra de la cafetería',
);

const List<PuntoEncuentro> catalogo = <PuntoEncuentro>[biblioteca, cafeteria];

/// Un encuentro de la conversación de las fixtures del chat. Por omisión lo
/// propuso el VENDEDOR para el jueves a las 13:00 en la Biblioteca.
Encuentro encuentro({
  String id = 'enc-1',
  String propuestoPor = idVendedor,
  EstadoEncuentro estado = EstadoEncuentro.propuesto,
  DateTime? fechaHora,
  PuntoEncuentro punto = biblioteca,
}) {
  return Encuentro(
    id: id,
    conversacionId: idConversacion,
    propuestoPor: propuestoPor,
    punto: punto,
    fechaHora: fechaHora ?? jueves13,
    estado: estado,
    creadoEn: ahora.subtract(const Duration(hours: 1)),
  );
}
