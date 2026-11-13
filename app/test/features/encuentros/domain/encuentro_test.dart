import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/chat/domain/entities/mensaje.dart';
import 'package:utrueque/features/encuentros/domain/entities/encuentro.dart';

import '../fixtures.dart';

void main() {
  final DateTime despues = jueves13.add(const Duration(minutes: 1));

  group('EstadoEncuentro', () {
    test('lee el valor de la base; uno desconocido se toma como cancelado', () {
      expect(EstadoEncuentro.desdeValor('aceptado'), EstadoEncuentro.aceptado);
      expect(EstadoEncuentro.desdeValor('vencido'), EstadoEncuentro.vencido);
      expect(EstadoEncuentro.desdeValor('otro'), EstadoEncuentro.cancelado);
      expect(EstadoEncuentro.desdeValor(null), EstadoEncuentro.cancelado);
      expect(EstadoEncuentro.propuesto.etiqueta, 'Esperando respuesta');
    });
  });

  group('Encuentro', () {
    test('Escenario 9: si ya pasó la hora, la propuesta vence y el confirmado ya pasó', () {
      expect(encuentro().estadoAl(ahora), EstadoEncuentro.propuesto);
      expect(encuentro().estadoAl(despues), EstadoEncuentro.vencido);
      expect(encuentro(estado: EstadoEncuentro.aceptado).estadoAl(despues), EstadoEncuentro.concluido);
      expect(encuentro(estado: EstadoEncuentro.rechazado).estadoAl(despues), EstadoEncuentro.rechazado);
    });

    test('Escenario 7: activo es pendiente o confirmado y con hora futura', () {
      expect(encuentro().estaActivo(ahora), isTrue);
      expect(encuentro(estado: EstadoEncuentro.aceptado).estaActivo(ahora), isTrue);
      expect(encuentro(estado: EstadoEncuentro.cancelado).estaActivo(ahora), isFalse);
      expect(encuentro().estaActivo(despues), isFalse);
    });

    test('Escenarios 2, 3 y 8: solo el otro responde una propuesta pendiente', () {
      expect(encuentro().esDe(idVendedor), isTrue);
      expect(encuentro().esDe(null), isFalse);
      expect(encuentro().puedeResponder(idComprador, ahora), isTrue);
      expect(encuentro().puedeResponder(idVendedor, ahora), isFalse);
      expect(encuentro(estado: EstadoEncuentro.aceptado).puedeResponder(idComprador, ahora), isFalse);
      expect(encuentro().puedeResponder(idComprador, despues), isFalse);
    });

    test('Escenario 4: la propuesta la cancela quien la hizo; el confirmado, cualquiera', () {
      expect(encuentro().puedeCancelar(idVendedor, ahora), isTrue);
      expect(encuentro().puedeCancelar(idComprador, ahora), isFalse);
      expect(encuentro(estado: EstadoEncuentro.aceptado).puedeCancelar(idComprador, ahora), isTrue);
      expect(encuentro(estado: EstadoEncuentro.aceptado).puedeCancelar(idVendedor, ahora), isTrue);
      expect(encuentro(estado: EstadoEncuentro.rechazado).puedeCancelar(idVendedor, ahora), isFalse);
    });
  });

  group('Mensaje con tipo (tarjeta de encuentro)', () {
    test('un mensaje normal no es tarjeta; uno con tipo y encuentro sí', () {
      expect(mensaje('m1').esDeEncuentro, isFalse);
      expect(mensaje('m1').tipo, TipoMensaje.texto);
      final Mensaje tarjeta = Mensaje(
        id: 'm2',
        conversacionId: idConversacion,
        autorId: idVendedor,
        texto: 'Propuso vernos en Biblioteca',
        creadoEn: ahora,
        tipo: TipoMensaje.propuesta,
        encuentroId: 'enc-1',
      );
      expect(tarjeta.esDeEncuentro, isTrue);
      expect(tarjeta, isNot(mensaje('m2')));
    });

    test('TipoMensaje lee el valor de la base; vacío o desconocido es texto', () {
      expect(TipoMensaje.desdeValor('aceptado'), TipoMensaje.aceptado);
      expect(TipoMensaje.desdeValor(null), TipoMensaje.texto);
      expect(TipoMensaje.desdeValor('raro'), TipoMensaje.texto);
    });
  });
}
