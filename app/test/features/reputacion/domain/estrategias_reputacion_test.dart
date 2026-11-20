import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/reputacion/domain/entities/reputacion.dart';
import 'package:utrueque/features/reputacion/domain/entities/resumen_reputacion.dart';
import 'package:utrueque/features/reputacion/domain/strategies/estrategias_reputacion.dart';

import '../fixtures.dart';

void main() {
  group('ResumenReputacion', () {
    test('cuenta el total, la suma de estrellas y cuántas hay de cada una', () {
      final ResumenReputacion r = resumen(una: 1, tres: 2, cinco: 3);

      expect(r.total, 6);
      expect(r.sumaEstrellas, 1 + 6 + 15);
      expect([for (int n = 1; n <= 5; n++) r.de(n)], [1, 0, 2, 0, 3]);
      expect(r.de(0), 0);
      expect(r.de(6), 0);
      expect(r.sinCalificaciones, isFalse);
    });

    test('Escenario 7: vacío no tiene calificaciones', () {
      const ResumenReputacion r = ResumenReputacion.vacio(idVendedor);
      expect(r.total, 0);
      expect(r.sinCalificaciones, isTrue);
      expect(r, resumen());
    });
  });

  group('Patrón Strategy: PromedioSimple', () {
    test('suma de estrellas entre el total', () {
      expect(const PromedioSimple().promedio(resumen(cuatro: 1, cinco: 1)), 4.5);
      expect(const PromedioSimple().esAjustada, isFalse);
    });

    test('sin calificaciones no hay promedio', () {
      expect(const PromedioSimple().promedio(resumen()), isNull);
    });
  });

  group('Patrón Strategy: PromedioAjustado (Escenario 8)', () {
    test('una sola de 5 da 4.25: no sube a nadie arriba de quien tiene muchas', () {
      expect(const PromedioAjustado().promedio(resumen(cinco: 1)), 4.25);
      expect(const PromedioAjustado().esAjustada, isTrue);
    });

    test('una sola de 1 da 3.25: tampoco hunde a nadie por un mal trato', () {
      expect(const PromedioAjustado().promedio(resumen(una: 1)), 3.25);
    });

    test('se pueden cambiar las calificaciones imaginarias', () {
      expect(const PromedioAjustado(imaginarias: 1, valorImaginario: 3).promedio(resumen(cinco: 1)), 4);
    });

    test('sin calificaciones no hay promedio', () {
      expect(const PromedioAjustado().promedio(resumen()), isNull);
    });
  });

  group('ElegirEstrategiaReputacion', () {
    const ElegirEstrategiaReputacion selector = ElegirEstrategiaReputacion();

    test('con menos de 5 calificaciones usa la ajustada', () {
      expect(selector.para(resumen(cinco: 4)), isA<PromedioAjustado>());
      expect(selector.para(resumen()), isA<PromedioAjustado>());
    });

    test('con 5 o más usa el promedio real', () {
      expect(selector.para(resumen(cinco: 5)), isA<PromedioSimple>());
      expect(selector.para(resumen(cuatro: 30, cinco: 10)), isA<PromedioSimple>());
    });

    test('el umbral se puede cambiar en un solo lugar', () {
      expect(const ElegirEstrategiaReputacion(minimoParaReal: 1).para(resumen(cinco: 1)), isA<PromedioSimple>());
    });
  });

  group('Reputacion.calcular', () {
    test('Escenario 8: una sola de 5 se muestra "4.3 · 1 calificación" (ajustada)', () {
      final Reputacion r = Reputacion.calcular(resumen(cinco: 1));

      expect(r.promedio, 4.25);
      expect(r.promedioTexto, '4.3');
      expect(r.ajustada, isTrue);
      expect(r.totalTexto, '1 calificación');
      expect(r.texto, '4.3 · 1 calificación');
      expect(r.estrellasLlenas, 4);
    });

    test('Escenario 8: con 5 calificaciones se muestra el promedio real', () {
      final Reputacion r = Reputacion.calcular(resumen(cuatro: 2, cinco: 3));

      expect(r.promedio, 4.6);
      expect(r.ajustada, isFalse);
      expect(r.texto, '4.6 · 5 calificaciones');
      expect(r.estrellasLlenas, 5);
      expect(r.total, 5);
    });

    test('Escenario 7: sin calificaciones, "Nuevo en UTrueque" y sin estrellas ni 0.0', () {
      final Reputacion r = Reputacion.calcular(resumen());

      expect(r.sinCalificaciones, isTrue);
      expect(r.promedio, isNull);
      expect(r.promedioTexto, isNull);
      expect(r.ajustada, isFalse);
      expect(r.texto, 'Nuevo en UTrueque · Sin calificaciones aún');
      expect(r.texto, isNot(contains('0.0')));
      expect(r.estrellasLlenas, 0);
    });

    test('redondea a una decimal', () {
      // (4 + 4 + 5) / 3 = 4.333…
      expect(
        Reputacion.calcular(resumen(cuatro: 2, cinco: 1), selector: const ElegirEstrategiaReputacion(minimoParaReal: 0))
            .promedioTexto,
        '4.3',
      );
    });

    test('las estrellas llenas no pasan de 0 a 5', () {
      expect(const Reputacion(resumen: ResumenReputacion.vacio('x'), promedio: 7).estrellasLlenas, 5);
      expect(const Reputacion(resumen: ResumenReputacion.vacio('x'), promedio: -1).estrellasLlenas, 0);
    });
  });
}
