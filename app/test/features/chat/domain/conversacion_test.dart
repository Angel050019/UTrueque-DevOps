import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/chat/domain/entities/conversacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';

import '../fixtures.dart';

void main() {
  group('Conversacion (HU-07)', () {
    test('desdePublicacion: el otro es el vendedor, con su nombre y foto (nunca el correo)', () {
      final Conversacion c = Conversacion.desdePublicacion('conv-9', publicacionDelVendedor(), creadaEn: hace10);

      expect(c.id, 'conv-9');
      expect(c.soyVendedor, isFalse);
      expect(c.otroId, idVendedor);
      expect(c.otroNombre, 'Ana López');
      expect(c.otroFotoUrl, 'https://avatars/ana.jpg');
      expect(c.publicacionTitulo, 'Calculadora Casio fx-991');
      expect(c.publicacionFotoUrl, 'https://fotos/1.jpg');
      expect(c.publicacionEstado, const Disponible());
      expect(c.noLeidos, 0);
      expect(c.creadaEn, hace10);
    });

    test('desdePublicacion sin nombre del dueño usa "Vendedor" y la fecha de hoy', () {
      final Conversacion c = Conversacion.desdePublicacion(
        'conv-9',
        publicacionDelVendedor(duenoNombre: null),
      );
      expect(c.otroNombre, 'Vendedor');
      expect(DateTime.now().difference(c.creadaEn).inMinutes, lessThan(1));
    });

    test('Escenario 11: acepta mensajes con Disponible o Reservado; no con Vendido ni borrada', () {
      expect(conversacion(estado: const Disponible()).aceptaMensajes, isTrue);
      expect(conversacion(estado: const Reservado()).aceptaMensajes, isTrue);
      expect(conversacion(estado: const Vendido()).aceptaMensajes, isFalse);
      expect(conversacion(eliminada: true).aceptaMensajes, isFalse);
    });

    test('una publicación borrada se muestra como "Publicación eliminada"', () {
      expect(conversacion(eliminada: true).tituloVisible, 'Publicación eliminada');
      expect(conversacion(eliminada: true).publicacionEliminada, isTrue);
      expect(conversacion().tituloVisible, 'Calculadora Casio fx-991');
    });

    test('fechaOrden: la del último mensaje, o la de creación si no hay mensajes', () {
      expect(conversacion().fechaOrden, hace10);
      final DateTime despues = hace10.add(const Duration(hours: 1));
      expect(conversacion(ultimoMensajeEn: despues).fechaOrden, despues);
    });

    test('Escenario 3: un mensaje del otro actualiza el último texto y suma un no leído', () {
      final Conversacion c = conversacion(noLeidos: 1).conMensaje(mensaje('m1', minuto: 5), miId: idComprador);
      expect(c.ultimoTexto, 'Mensaje m1');
      expect(c.ultimoAutorId, idVendedor);
      expect(c.ultimoMensajeEn, hace10.add(const Duration(minutes: 5)));
      expect(c.noLeidos, 2);
    });

    test('un mensaje mío no suma no leídos', () {
      final Conversacion c = conversacion().conMensaje(mensaje('m1', autor: idComprador), miId: idComprador);
      expect(c.noLeidos, 0);
      expect(c.ultimoAutorId, idComprador);
    });

    test('Escenario 8: leida() deja los no leídos en 0 y conserva lo demás', () {
      final Conversacion c = conversacion(noLeidos: 3, ultimoTexto: 'Hola');
      expect(c.leida().noLeidos, 0);
      expect(c.leida().ultimoTexto, 'Hola');
      expect(c.leida().id, c.id);
    });

    test('un mensaje sabe quién lo escribió', () {
      expect(mensaje('m1').esDe(idVendedor), isTrue);
      expect(mensaje('m1').esDe(idComprador), isFalse);
      expect(mensaje('m1').esDe(null), isFalse);
    });
  });
}
