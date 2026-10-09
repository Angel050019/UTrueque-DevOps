import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/publicaciones/data/models/publicacion_model.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';

import '../fixtures.dart';

void main() {
  group('PublicacionModel', () {
    test('fromMap convierte una fila de Venta con precio numérico', () {
      final PublicacionModel modelo = PublicacionModel.fromMap(const <String, dynamic>{
        'id': 'pub-1',
        'usuario_id': idAlumno,
        'titulo': tituloValido,
        'descripcion': descripcionValida,
        'categoria_id': 2,
        'modalidad': 'venta',
        'precio': 150.5,
        'estado': 'disponible',
        'fotos': <dynamic>[rutaFoto1, rutaFoto2],
        'created_at': '2026-10-07T18:00:00Z',
      });

      expect(modelo.usuarioId, idAlumno);
      expect(modelo.categoriaId, 2);
      expect(modelo.modalidad, Modalidad.venta);
      expect(modelo.precio, 150.5);
      expect(modelo.estado, EstadoPublicacion.inicial);
      expect(modelo.fotos, [rutaFoto1, rutaFoto2]);
      expect(modelo.creadaEn, DateTime.utc(2026, 10, 7, 18));
    });

    test('fromMap acepta precio nulo, precio como texto y fila sin fecha ni fotos', () {
      final Map<String, dynamic> base = <String, dynamic>{
        'id': 'pub-2',
        'usuario_id': idAlumno,
        'titulo': 'Bata',
        'descripcion': 'Bata de laboratorio talla M',
        'categoria_id': 3,
        'modalidad': 'gratis',
        'precio': null,
        'estado': 'reservado',
      };

      final PublicacionModel gratis = PublicacionModel.fromMap(base);
      final PublicacionModel conTexto =
          PublicacionModel.fromMap({...base, 'modalidad': 'venta', 'precio': '99.90'});

      expect(gratis.precio, isNull);
      expect(gratis.fotos, isEmpty);
      expect(gratis.creadaEn, isNull);
      expect(gratis.estado, const Reservado());
      expect(conTexto.precio, 99.9);
    });

    test('paraCrear NO envía usuario_id ni estado (los decide el servidor)', () {
      final Map<String, dynamic> cuerpo = PublicacionModel.paraCrear(
        titulo: tituloValido,
        descripcion: descripcionValida,
        categoriaId: 2,
        modalidad: Modalidad.venta,
        precio: 150,
        fotos: const [rutaFoto1],
      );

      expect(cuerpo, <String, dynamic>{
        'titulo': tituloValido,
        'descripcion': descripcionValida,
        'categoria_id': 2,
        'modalidad': 'venta',
        'precio': 150.0,
        'fotos': [rutaFoto1],
      });
      expect(cuerpo.containsKey('usuario_id'), isFalse);
      expect(cuerpo.containsKey('estado'), isFalse);
    });

    test('paraCrear descarta el precio fuera de Venta', () {
      final Map<String, dynamic> cuerpo = PublicacionModel.paraCrear(
        titulo: tituloValido,
        descripcion: descripcionValida,
        categoriaId: 2,
        modalidad: Modalidad.intercambio,
        precio: 150,
        fotos: const [rutaFoto1],
      );

      expect(cuerpo['precio'], isNull);
      expect(cuerpo['modalidad'], 'intercambio');
    });
  });

  group('PublicacionModel para el Feed', () {
    test('lee el dueño y la categoría unidos y arma la URL de la portada', () {
      final PublicacionModel modelo = PublicacionModel.fromMap(
        const <String, dynamic>{
          'id': 'pub-3',
          'usuario_id': idAlumno,
          'titulo': tituloValido,
          'descripcion': descripcionValida,
          'categoria_id': 2,
          'modalidad': 'intercambio',
          'precio': null,
          'estado': 'disponible',
          'fotos': <dynamic>[rutaFoto1, rutaFoto2],
          'usuarios': <String, dynamic>{'nombre_mostrar': 'Ana López'},
          'categorias': <String, dynamic>{'nombre': 'Calculadoras'},
        },
        urlFoto: (ruta) => 'https://fotos/$ruta',
      );

      expect(modelo.portadaUrl, 'https://fotos/$rutaFoto1');
      expect(modelo.duenoNombre, 'Ana López');
      expect(modelo.categoriaNombre, 'Calculadoras');
    });

    test('sin fotos, sin urlFoto o sin tablas unidas deja esos datos en null', () {
      const Map<String, dynamic> fila = <String, dynamic>{
        'id': 'pub-4',
        'usuario_id': idAlumno,
        'titulo': tituloValido,
        'descripcion': descripcionValida,
        'categoria_id': 2,
        'modalidad': 'gratis',
        'estado': 'disponible',
        'fotos': <dynamic>[rutaFoto1],
        'usuarios': null,
      };

      final PublicacionModel sinUrl = PublicacionModel.fromMap(fila);
      final PublicacionModel sinFotos =
          PublicacionModel.fromMap(const {...fila, 'fotos': <dynamic>[]}, urlFoto: (r) => r);

      expect(sinUrl.portadaUrl, isNull);
      expect(sinUrl.duenoNombre, isNull);
      expect(sinUrl.categoriaNombre, isNull);
      expect(sinFotos.portadaUrl, isNull);
    });
  });

  group('CategoriaModel', () {
    test('fromMap convierte una fila del catálogo', () {
      final CategoriaModel modelo =
          CategoriaModel.fromMap(const <String, dynamic>{'id': 2, 'nombre': 'Calculadoras', 'orden': 2});

      expect(modelo.id, categoriaCalculadoras.id);
      expect(modelo.nombre, categoriaCalculadoras.nombre);
    });
  });
}
