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

  group('PublicacionModel para el Feed y el Detalle (HU-04)', () {
    test('lee la vista publicaciones_detalle: dueño, división, carrera, categoría y URLs de las fotos',
        () {
      final PublicacionModel modelo = PublicacionModel.fromMap(
        const <String, dynamic>{
          'id': 'pub-3',
          'usuario_id': idAlumno,
          'titulo': tituloValido,
          'descripcion': descripcionValida,
          'categoria_id': 2,
          'categoria_nombre': 'Calculadoras',
          'modalidad': 'intercambio',
          'precio': null,
          'estado': 'reservado',
          'fotos': <dynamic>[rutaFoto1, rutaFoto2],
          'created_at': '2026-10-13T18:00:00.123456+00:00',
          'dueno_nombre': 'Ana López',
          'dueno_foto_url': 'https://fotos/avatar.jpg',
          'dueno_division_id': 11,
          'dueno_division': 'Mecatrónica, Desarrollo de Software e Ingeniería Civil',
          'dueno_carrera_id': 101,
          'dueno_carrera': 'Ingeniería en Desarrollo y Gestión de Software',
        },
        urlFoto: (ruta) => 'https://fotos/$ruta',
      );

      expect(modelo.portadaUrl, 'https://fotos/$rutaFoto1');
      expect(modelo.fotosUrls, ['https://fotos/$rutaFoto1', 'https://fotos/$rutaFoto2']);
      expect(modelo.categoriaNombre, 'Calculadoras');
      expect(modelo.duenoNombre, 'Ana López');
      expect(modelo.duenoFotoUrl, 'https://fotos/avatar.jpg');
      expect(modelo.duenoDivision, 'Mecatrónica, Desarrollo de Software e Ingeniería Civil');
      expect(modelo.duenoCarrera, 'Ingeniería en Desarrollo y Gestión de Software');
      expect(modelo.estado, const Reservado());
      expect(modelo.creadaEn, DateTime.utc(2026, 10, 13, 18, 0, 0, 123, 456));
      expect(modelo.esDe(idAlumno), isTrue);
      expect(modelo.esDe('otro'), isFalse);
      expect(modelo.esDe(null), isFalse);
    });

    test('sin fotos, sin urlFoto o sin datos del dueño deja esos datos vacíos', () {
      const Map<String, dynamic> fila = <String, dynamic>{
        'id': 'pub-4',
        'usuario_id': idAlumno,
        'titulo': tituloValido,
        'descripcion': descripcionValida,
        'categoria_id': 2,
        'modalidad': 'gratis',
        'estado': 'disponible',
        'fotos': <dynamic>[rutaFoto1],
        'dueno_nombre': null,
      };

      final PublicacionModel sinUrl = PublicacionModel.fromMap(fila);
      // Copia de la fila con la lista de fotos vacía.
      final Map<String, dynamic> filaSinFotos = Map<String, dynamic>.of(fila)
        ..['fotos'] = <dynamic>[];
      final PublicacionModel sinFotos = PublicacionModel.fromMap(filaSinFotos, urlFoto: (r) => r);

      expect(sinUrl.portadaUrl, isNull);
      expect(sinUrl.fotosUrls, isEmpty);
      expect(sinUrl.duenoNombre, isNull);
      expect(sinUrl.duenoFotoUrl, isNull);
      expect(sinUrl.duenoDivision, isNull);
      expect(sinUrl.duenoCarrera, isNull);
      expect(sinUrl.categoriaNombre, isNull);
      expect(sinFotos.portadaUrl, isNull);
      expect(sinFotos.fotosUrls, isEmpty);
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
  group('PublicacionModel (HU-06)', () {
    test('paraEditar manda los mismos campos que al crear, sin dueño ni estado', () {
      final Map<String, dynamic> datos = PublicacionModel.paraEditar(
        titulo: tituloValido,
        descripcion: descripcionValida,
        categoriaId: 2,
        modalidad: Modalidad.gratis,
        precio: 150,
        fotos: const [rutaFoto1],
      );

      expect(datos, <String, dynamic>{
        'titulo': tituloValido,
        'descripcion': descripcionValida,
        'categoria_id': 2,
        'modalidad': 'gratis',
        // Fuera de Venta el precio se manda vacío.
        'precio': null,
        'fotos': [rutaFoto1],
      });
      expect(datos.containsKey('usuario_id'), isFalse);
      expect(datos.containsKey('estado'), isFalse);
    });

    test('paraCambiarEstado manda SOLO el estado nuevo', () {
      expect(PublicacionModel.paraCambiarEstado(const Reservado()), {'estado': 'reservado'});
      expect(PublicacionModel.paraCambiarEstado(const Vendido()), {'estado': 'vendido'});
    });

    test('la función de "Mis publicaciones" es mis_publicaciones', () {
      expect(PublicacionModel.funcionMisPublicaciones, 'mis_publicaciones');
    });
  });
}
