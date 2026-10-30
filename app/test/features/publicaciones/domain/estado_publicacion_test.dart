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

    test('HU-04 Escenario 9: Reservado y Vendido no permiten contactar y muestran su aviso', () {
      expect(const Disponible().aceptaSolicitudes, isTrue);
      expect(const Disponible().aviso, isNull);
      expect(const Reservado().aceptaSolicitudes, isFalse);
      expect(const Reservado().aviso, 'Este artículo está reservado: el dueño ya está en trato.');
      expect(const Vendido().aceptaSolicitudes, isFalse);
      expect(const Vendido().aviso, 'Este artículo ya fue vendido.');
    });

    test('HU-04: solo las Vendidas salen del Feed', () {
      expect(const Disponible().visibleEnFeed, isTrue);
      expect(const Reservado().visibleEnFeed, isTrue);
      expect(const Vendido().visibleEnFeed, isFalse);
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
  group('HU-06: acciones del dueño según el estado (patrón State)', () {
    test('Disponible: Reservar o Vender, y se puede editar y borrar', () {
      const EstadoPublicacion estado = Disponible();
      expect(estado.acciones, [AccionEstado.reservar, AccionEstado.marcarVendido]);
      expect(estado.sePuedeEditar, isTrue);
      expect(estado.sePuedeBorrar, isTrue);
      expect(estado.esFinal, isFalse);
    });

    test('Reservado: Volver a Disponible o Vender; no se edita ni se borra', () {
      const EstadoPublicacion estado = Reservado();
      expect(estado.acciones, [AccionEstado.liberar, AccionEstado.marcarVendido]);
      expect(estado.sePuedeEditar, isFalse);
      expect(estado.sePuedeBorrar, isFalse);
      expect(estado.esFinal, isFalse);
    });

    test('Vendido: es final, sin acciones; no se edita ni se borra', () {
      const EstadoPublicacion estado = Vendido();
      expect(estado.acciones, isEmpty);
      expect(estado.sePuedeEditar, isFalse);
      expect(estado.sePuedeBorrar, isFalse);
      expect(estado.esFinal, isTrue);
    });

    test('aplicar hace la transición que pide cada acción', () {
      expect(const Disponible().aplicar(AccionEstado.reservar), const Reservado());
      expect(const Disponible().aplicar(AccionEstado.marcarVendido), const Vendido());
      expect(const Reservado().aplicar(AccionEstado.liberar), const Disponible());
      expect(const Reservado().aplicar(AccionEstado.marcarVendido), const Vendido());
    });

    test('Escenario 9: aplicar una acción que el estado no permite lanza el fallo', () {
      expect(
        () => const Disponible().aplicar(AccionEstado.liberar),
        throwsA(isA<TransicionNoPermitidaFailure>()),
      );
      expect(
        () => const Reservado().aplicar(AccionEstado.reservar),
        throwsA(isA<TransicionNoPermitidaFailure>()),
      );
      for (final AccionEstado accion in AccionEstado.values) {
        expect(() => const Vendido().aplicar(accion), throwsA(isA<TransicionNoPermitidaFailure>()));
      }
    });

    test('cada acción tiene el texto de su botón', () {
      expect(AccionEstado.reservar.etiqueta, 'Marcar como Reservado');
      expect(AccionEstado.liberar.etiqueta, 'Volver a Disponible');
      expect(AccionEstado.marcarVendido.etiqueta, 'Marcar como Vendido');
    });
  });
}
