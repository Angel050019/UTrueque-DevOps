import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/reputacion/domain/entities/trato.dart';
import 'package:utrueque/features/reputacion/domain/validators/calificacion_validator.dart';

import '../fixtures.dart';

void main() {
  const CalificacionValidator v = CalificacionValidator();

  group('Estrellas (Escenarios 3 y 4)', () {
    test('de 1 a 5 son válidas', () {
      for (int n = 1; n <= 5; n++) {
        expect(v.validarEstrellas(n), isNull);
      }
    });

    test('sin elegir, 0 o 6 no son válidas', () {
      expect(v.validarEstrellas(null), CalificacionValidator.mensajeEstrellas);
      expect(v.validarEstrellas(0), CalificacionValidator.mensajeEstrellas);
      expect(v.validarEstrellas(6), CalificacionValidator.mensajeEstrellas);
    });
  });

  group('Comentario (Escenario 12)', () {
    test('es opcional: vacío o solo espacios es válido', () {
      expect(v.validarComentario(''), isNull);
      expect(v.validarComentario('   '), isNull);
    });

    test('acepta letras con acentos, números, signos permitidos y saltos de línea', () {
      expect(v.validarComentario('Muy puntual, ¡gracias!\nTodo bien (10/10).'), isNull);
    });

    test('hasta 200 caracteres; 201 no', () {
      expect(v.validarComentario('a' * 200), isNull);
      expect(v.validarComentario('a' * 201), CalificacionValidator.mensajeLargo);
    });

    test('rechaza < > ; comillas y emojis', () {
      for (final String texto in ['<script>', 'hola;', "it's", 'genial 😀', 'a"b']) {
        expect(v.validarComentario(texto), CalificacionValidator.mensajeCaracteres, reason: texto);
      }
    });

    test('limpiar quita espacios de más y deja null si está vacío', () {
      expect(v.limpiar('  Muy bien  '), 'Muy bien');
      expect(v.limpiar('   '), isNull);
      expect(v.limpiar(null), isNull);
    });
  });

  test('"Enviar calificación" se habilita solo con estrellas y un comentario válido', () {
    expect(v.sePuedeEnviar(null, ''), isFalse);
    expect(v.sePuedeEnviar(5, ''), isTrue);
    expect(v.sePuedeEnviar(5, '<b>'), isFalse);
  });

  group('TratoPorCalificar (Escenario 10)', () {
    test('se vence a los 14 días de la venta', () {
      expect(trato(diasDesdeVenta: 13).vencidoAl(ahoraRep), isFalse);
      expect(trato(diasDesdeVenta: 14).vencidoAl(ahoraRep), isTrue);
      expect(trato(diasDesdeVenta: 20).vencidoAl(ahoraRep), isTrue);
    });

    test('días que quedan', () {
      expect(trato(diasDesdeVenta: 1).diasRestantesAl(ahoraRep), 13);
      expect(trato(diasDesdeVenta: 15).diasRestantesAl(ahoraRep), 0);
    });

    test('invitación con el nombre del otro', () {
      expect(trato().invitacion, 'Califica tu trato con Ana López');
      expect(trato(soyVendedor: true).invitacion, 'Califica tu trato con Beto Ruiz');
    });

    test('igualdad por valor', () {
      expect(trato(), trato());
      expect(trato(), isNot(trato(ventaId: 'otra')));
    });
  });

  group('EleccionVenta (Escenarios 1 y 2)', () {
    test('a alguien o fuera de UTrueque', () {
      const EleccionVenta a = EleccionVenta.a(idConversacion, nombre: 'Beto Ruiz');
      const EleccionVenta fuera = EleccionVenta.fueraDeUTrueque();

      expect(a.fueraDeUTrueque, isFalse);
      expect(a.conversacionId, idConversacion);
      expect(fuera.fueraDeUTrueque, isTrue);
      expect(fuera.conversacionId, isNull);
      expect(a, const EleccionVenta.a(idConversacion, nombre: 'Beto Ruiz'));
    });

    test('las demás entidades se comparan por valor', () {
      expect(recibida('c1'), recibida('c1'));
      expect(beto, isNot(caro));
      expect(
        PaginaCalificaciones(calificaciones: [recibida('c1')], hayMas: true),
        PaginaCalificaciones(calificaciones: [recibida('c1')], hayMas: true),
      );
    });
  });
}
