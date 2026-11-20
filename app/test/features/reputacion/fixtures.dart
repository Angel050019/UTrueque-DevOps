import 'package:mocktail/mocktail.dart';
import 'package:utrueque/features/reputacion/domain/entities/resumen_reputacion.dart';
import 'package:utrueque/features/reputacion/domain/entities/trato.dart';
import 'package:utrueque/features/reputacion/domain/repositories/reputacion_repository.dart';

import '../chat/fixtures.dart';

export '../chat/fixtures.dart';

class MockReputacionRepository extends Mock implements ReputacionRepository {}

/// "Ahora" en las pruebas de HU-09: jueves 19 de noviembre de 2026 a las
/// 12:00 en la universidad (18:00 UTC).
final DateTime ahoraRep = DateTime.utc(2026, 11, 19, 18, 0);
DateTime relojRep() => ahoraRep;

/// Un trato que el COMPRADOR (Beto) tiene por calificar: le compró la
/// calculadora a Ana hace [diasDesdeVenta] días.
TratoPorCalificar trato({
  String ventaId = 'venta-1',
  int diasDesdeVenta = 1,
  bool soyVendedor = false,
  String? conversacionId = idConversacion,
}) {
  final DateTime vendidaEn = ahoraRep.subtract(Duration(days: diasDesdeVenta));
  return TratoPorCalificar(
    ventaId: ventaId,
    conversacionId: conversacionId,
    publicacionId: 'pub-1',
    publicacionTitulo: 'Calculadora Casio fx-991',
    soyVendedor: soyVendedor,
    otroId: soyVendedor ? idComprador : idVendedor,
    otroNombre: soyVendedor ? 'Beto Ruiz' : 'Ana López',
    vendidaEn: vendidaEn,
    venceEn: vendidaEn.add(const Duration(days: TratoPorCalificar.diasParaCalificar)),
  );
}

/// Una calificación que recibió Ana, [n] horas antes de [ahoraRep].
CalificacionRecibida recibida(String id, {int estrellas = 5, int horas = 1, String? comentario = 'Muy puntual.'}) {
  return CalificacionRecibida(
    id: id,
    estrellas: estrellas,
    comentario: comentario,
    creadaEn: ahoraRep.subtract(Duration(hours: horas)),
    autorId: idComprador,
    autorNombre: 'Beto Ruiz',
    publicacionTitulo: 'Calculadora Casio fx-991',
    comoVendedor: true,
  );
}

/// Resumen con esas cantidades de 1 a 5 estrellas.
ResumenReputacion resumen({int una = 0, int dos = 0, int tres = 0, int cuatro = 0, int cinco = 0}) =>
    ResumenReputacion(usuarioId: idVendedor, una: una, dos: dos, tres: tres, cuatro: cuatro, cinco: cinco);

const CompradorPosible beto = CompradorPosible(conversacionId: idConversacion, compradorId: idComprador, nombre: 'Beto Ruiz');
const CompradorPosible caro = CompradorPosible(conversacionId: 'conv-2', compradorId: 'id-caro', nombre: 'Caro Mena');
