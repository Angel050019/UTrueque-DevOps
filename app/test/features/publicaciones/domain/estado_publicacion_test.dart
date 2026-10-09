import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';

/// Patrón State: ciclo de vida Disponible → Reservado → Vendido.
void main() {
  group('EstadoPublicacion (patrón State)', () {
    test('toda publicación nace en Disponible y acepta solicitudes', () {
      expect(EstadoPublicacion.inicial, const Disponible());
      expect(EstadoPublicacion.inicial.valor, 'disponible');
      expect(EstadoPublicacion.inicial.aceptaSolicitudes, isTrue);
    });

    test('Disponible puede reservarse o venderse directamente', () {
      expect(const Disponible().reservar(), const Reservado());
      expect(const Disponible().marcarVendido(), const Vendido());
    });

    test('Reservado puede liberarse (volver a Disponible) o venderse', () {
      expect(const Reservado().liberar(), const Disponible());
      expect(const Reservado().marcarVendido(), const Vendido());
      expect(const Reservado().aceptaSolicitudes, isFalse);
    });

    test('Disponible no puede "liberarse" ni Reservado volver a reservarse', () {
      expect(() => const Disponible().liberar(), throwsA(isA<TransicionNoPermitidaFailure>()));
      expect(() => const Reservado().reservar(), throwsA(isA<TransicionNoPermitidaFailure>()));
    });

    test('Vendido es el estado final: no acepta ningún cambio', () {
      const EstadoPublicacion vendido = Vendido();
      expect(vendido.aceptaSolicitudes, isFalse);
      expect(vendido.reservar, throwsA(isA<TransicionNoPermitidaFailure>()));
      expect(vendido.liberar, throwsA(isA<TransicionNoPermitidaFailure>()));
      expect(
        vendido.marcarVendido,
        throwsA(isA<TransicionNoPermitidaFailure>().having(
          (f) => f.mensaje,
          'mensaje',
          'Una publicación Vendido no puede pasar a Vendido.',
        )),
      );
    });

    test('desdeValor convierte el texto de la base de datos en el estado', () {
      expect(EstadoPublicacion.desdeValor('disponible'), const Disponible());
      expect(EstadoPublicacion.desdeValor('reservado').etiqueta, 'Reservado');
      expect(EstadoPublicacion.desdeValor('vendido').etiqueta, 'Vendido');
      expect(() => EstadoPublicacion.desdeValor('perdido'), throwsArgumentError);
    });
  });

  group('Modalidad', () {
    test('solo Venta requiere precio', () {
      expect(Modalidad.venta.requierePrecio, isTrue);
      expect(Modalidad.intercambio.requierePrecio, isFalse);
      expect(Modalidad.gratis.requierePrecio, isFalse);
    });

    test('desdeValor convierte el texto de la base de datos', () {
      expect(Modalidad.desdeValor('gratis'), Modalidad.gratis);
      expect(Modalidad.desdeValor('venta').etiqueta, 'Venta');
      expect(() => Modalidad.desdeValor('subasta'), throwsArgumentError);
    });
  });
}
