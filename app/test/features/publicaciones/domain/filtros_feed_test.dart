import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/publicaciones/domain/entities/filtros_feed.dart';

void main() {
  group('FiltrosFeed (HU-05)', () {
    test('sin nada puesto no hay filtros', () {
      // ARRANGE + ACT
      const FiltrosFeed filtros = FiltrosFeed();

      // ASSERT
      expect(filtros.hayFiltros, isFalse);
      expect(filtros.tieneTexto, isFalse);
      expect(filtros.filtraPorDivisionOCarrera, isFalse);
    });

    test('Escenario 2: el texto se limpia (espacios de más) y cuenta como filtro', () {
      // ACT
      final FiltrosFeed filtros = const FiltrosFeed().conTexto('  calculadora    cientifica  ');

      // ASSERT
      expect(filtros.texto, 'calculadora cientifica');
      expect(filtros.tieneTexto, isTrue);
      expect(filtros.hayFiltros, isTrue);
    });

    test('Escenario 2: un texto de solo espacios es lo mismo que no buscar', () {
      expect(const FiltrosFeed().conTexto('   '), const FiltrosFeed());
    });

    test('el texto se recorta a 100 caracteres', () {
      // ARRANGE
      final String largo = 'a' * 150;

      // ACT
      final String recortado = FiltrosFeed.normalizarTexto(largo);

      // ASSERT
      expect(recortado.length, FiltrosFeed.maximoCaracteres);
    });

    test('al recortar no parte un emoji a la mitad', () {
      // ARRANGE: 99 letras y un emoji (2 unidades) que quedaría partido.
      final String texto = '${'a' * 99}😀 libro';

      // ACT
      final String recortado = FiltrosFeed.normalizarTexto(texto);

      // ASSERT
      expect(recortado, 'a' * 99);
    });

    test('Escenario 4: la categoría se pone y se quita ("Todo") sin tocar lo demás', () {
      // ARRANGE
      final FiltrosFeed base = const FiltrosFeed(divisionId: 11).conTexto('libro');

      // ACT
      final FiltrosFeed conCategoria = base.conCategoria(2);
      final FiltrosFeed todo = conCategoria.conCategoria(null);

      // ASSERT
      expect(conCategoria, const FiltrosFeed(texto: 'libro', categoriaId: 2, divisionId: 11));
      expect(todo, base);
    });

    test('Escenarios 1 y 3: división y carrera se ponen y se quitan juntas', () {
      // ARRANGE
      const FiltrosFeed base = FiltrosFeed(texto: 'bata', categoriaId: 3);

      // ACT
      final FiltrosFeed conCarrera = base.conDivisionYCarrera(divisionId: 11, carreraId: 102);
      final FiltrosFeed sinCarrera = conCarrera.conDivisionYCarrera();

      // ASSERT
      expect(conCarrera.filtraPorDivisionOCarrera, isTrue);
      expect(conCarrera.carreraId, 102);
      expect(conCarrera.texto, 'bata');
      expect(conCarrera.categoriaId, 3);
      expect(sinCarrera, base);
    });

    test('solo con división (sin carrera) también filtra', () {
      expect(const FiltrosFeed(divisionId: 12).filtraPorDivisionOCarrera, isTrue);
      expect(const FiltrosFeed(divisionId: 12).hayFiltros, isTrue);
    });
  });
}
