import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/core/utils/formato_fecha.dart';

void main() {
  group('formatearFecha (HU-04)', () {
    test('escribe la fecha en español con el mes en letra', () {
      expect(formatearFecha(DateTime(2026, 10, 13, 12)), '13 de octubre de 2026');
      expect(formatearFecha(DateTime(2026, 1, 5, 12)), '5 de enero de 2026');
      expect(formatearFecha(DateTime(2026, 12, 31, 12)), '31 de diciembre de 2026');
    });
  });

  group('formatearHora y formatearMomento (HU-07)', () {
    final DateTime ahora = DateTime(2026, 11, 6, 18, 30);

    test('la hora con dos dígitos', () {
      expect(formatearHora(DateTime(2026, 11, 6, 9, 5)), '09:05');
      expect(formatearHora(DateTime(2026, 11, 6, 23, 59)), '23:59');
    });

    test('hoy muestra la hora', () {
      expect(formatearMomento(DateTime(2026, 11, 6, 9, 5), ahora: ahora), '09:05');
    });

    test('ayer muestra "Ayer"', () {
      expect(formatearMomento(DateTime(2026, 11, 5, 23, 0), ahora: ahora), 'Ayer');
    });

    test('antes de ayer muestra el día y el mes', () {
      expect(formatearMomento(DateTime(2026, 11, 2, 10), ahora: ahora), '2 nov');
    });

    test('de otro año agrega el año', () {
      expect(formatearMomento(DateTime(2025, 12, 24, 10), ahora: ahora), '24 dic 2025');
    });

    test('una fecha futura (reloj desfasado) muestra la hora', () {
      expect(formatearMomento(DateTime(2026, 11, 7, 8, 0), ahora: ahora), '08:00');
    });

    test('sin "ahora" usa la fecha del celular', () {
      final DateTime hace = DateTime.now().subtract(const Duration(minutes: 1));
      expect(formatearMomento(hace), formatearHora(hace));
    });
  });
}
