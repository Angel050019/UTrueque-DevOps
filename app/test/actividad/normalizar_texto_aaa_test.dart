// Actividad: 5 casos de prueba con flutter_test y el patrón AAA.

// Función a probar: FiltrosFeed.normalizarTexto (HU-05, Búsqueda y filtros).
// Recibe el texto que el estudiante escribe en el buscador (String) y
// devuelve el texto limpio que la app manda a Supabase (String):
//   · sin espacios al inicio ni al final,
//   · con los espacios repetidos (o tabulaciones y saltos de línea) juntados
//     en uno solo,
//   · recortado a 100 caracteres como máximo, sin partir un emoji.


import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/publicaciones/domain/entities/filtros_feed.dart';

void main() {
  group('FiltrosFeed.normalizarTexto (HU-05) — patrón AAA', () {
    test('CP-A1: quita los espacios de las orillas y junta los repetidos', () {
      // ARRANGE: lo que escribe el estudiante, con espacios de más.
      const String escrito = '  calculadora   cientifica  ';

      // ACT: se limpia el texto antes de buscar.
      final String resultado = FiltrosFeed.normalizarTexto(escrito);

      // ASSERT: queda una sola separación entre palabras y nada en las orillas.
      expect(resultado, 'calculadora cientifica');
    });

    test('CP-A2: convierte tabulaciones y saltos de línea en un espacio y respeta los acentos',
        () {
      // ARRANGE: texto pegado desde otra app, con tabulación y salto de línea.
      const String escrito = '\tlibro\nde   cálculo ';

      // ACT
      final String resultado = FiltrosFeed.normalizarTexto(escrito);

      // ASSERT: los acentos no se tocan (los quita la base de datos al buscar).
      expect(resultado, 'libro de cálculo');
    });

    test('CP-A3: un texto de solo espacios queda vacío (no se busca nada)', () {
      // ARRANGE: el estudiante solo presionó la barra espaciadora.
      const String escrito = '     ';

      // ACT
      final String resultado = FiltrosFeed.normalizarTexto(escrito);

      // ASSERT: texto vacío = el Feed se muestra sin filtro de texto.
      expect(resultado, isEmpty);
    });

    test('CP-A4: un texto de 150 caracteres se recorta a 100', () {
      // ARRANGE: texto más largo de lo permitido (regla de seguridad).
      final String escrito = 'a' * 150;

      // ACT
      final String resultado = FiltrosFeed.normalizarTexto(escrito);

      // ASSERT: nunca se manda más del máximo al servidor.
      expect(resultado.length, FiltrosFeed.maximoCaracteres);
      expect(resultado, 'a' * 100);
    });

    test('CP-A5: al recortar no parte un emoji a la mitad', () {
      // ARRANGE: 99 letras y luego un emoji, que ocupa 2 unidades; el corte
      // en 100 caería justo a la mitad del emoji.
      final String escrito = '${'a' * 99}😀 libro';

      // ACT
      final String resultado = FiltrosFeed.normalizarTexto(escrito);

      // ASSERT: el emoji se deja fuera completo en lugar de mandarlo roto.
      expect(resultado, 'a' * 99);
      expect(resultado.length, 99);
    });
  });
}