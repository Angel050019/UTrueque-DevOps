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
}
