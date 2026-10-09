import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/core/utils/formato_precio.dart';

void main() {
  group('formatearPrecio', () {
    test('omite los centavos cuando son cero', () {
      expect(formatearPrecio(150), r'$150');
      expect(formatearPrecio(0), r'$0');
    });

    test('muestra dos decimales cuando hay centavos', () {
      expect(formatearPrecio(150.5), r'$150.50');
      expect(formatearPrecio(99.05), r'$99.05');
    });

    test('separa los miles con coma', () {
      expect(formatearPrecio(1200), r'$1,200');
      expect(formatearPrecio(100000), r'$100,000');
      expect(formatearPrecio(1234567.89), r'$1,234,567.89');
    });
  });
}
