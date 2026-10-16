import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/validators/publicacion_validator.dart';

import '../fixtures.dart';

void main() {
  const PublicacionValidator validador = PublicacionValidator();

  group('validarTitulo y validarDescripcion', () {
    test('aceptan textos dentro del rango (sin contar espacios de sobra)', () {
      expect(validador.validarTitulo('  Bata  '), isNull);
      expect(validador.validarDescripcion(descripcionValida), isNull);
    });

    test('rechazan textos vacíos, cortos o largos con el mensaje del Escenario 5', () {
      expect(validador.validarTitulo(''), PublicacionValidator.mensajeTitulo);
      expect(validador.validarTitulo('ab'), PublicacionValidator.mensajeTitulo);
      expect(validador.validarTitulo('a' * 81), PublicacionValidator.mensajeTitulo);
      expect(validador.validarDescripcion('corta'), PublicacionValidator.mensajeDescripcion);
      expect(validador.validarDescripcion('a' * 501), PublicacionValidator.mensajeDescripcion);
      expect(PublicacionValidator.mensajeTitulo, 'Escribe un título de 3 a 80 caracteres.');
      expect(
        PublicacionValidator.mensajeDescripcion,
        'Escribe una descripción de 10 a 500 caracteres.',
      );
    });
  });

  group('validarCategoria y validarModalidad', () {
    test('son obligatorias', () {
      expect(validador.validarCategoria(null), 'Elige una categoría.');
      expect(validador.validarCategoria(categoriaLibros), isNull);
      expect(validador.validarModalidad(null), 'Elige una modalidad.');
      expect(validador.validarModalidad(Modalidad.gratis), isNull);
    });
  });

  group('validarPrecio', () {
    test('Escenario 2: Venta con precio vacío muestra el mensaje exacto del issue #4', () {
      expect(
        validador.validarPrecio(Modalidad.venta, '   '),
        'Debe especificar un costo para la modalidad Venta',
      );
    });

    test(r'Escenario 3: Venta con precio 0 muestra "El precio debe ser mayor a $0."', () {
      expect(validador.validarPrecio(Modalidad.venta, '0'), r'El precio debe ser mayor a $0.');
      expect(validador.validarPrecio(Modalidad.venta, '0.00'), PublicacionValidator.mensajePrecioCero);
    });

    test('rechaza textos que no son precio (negativos, letras, 3 decimales)', () {
      for (final String texto in ['-5', 'abc', '10.999', '1.2.3']) {
        expect(
          validador.validarPrecio(Modalidad.venta, texto),
          PublicacionValidator.mensajePrecioFormato,
          reason: texto,
        );
      }
    });

    test('acepta precios válidos en Venta', () {
      expect(validador.validarPrecio(Modalidad.venta, '150'), isNull);
      expect(validador.validarPrecio(Modalidad.venta, r'$ 150.50'), isNull);
    });

    test('ignora el precio en Intercambio, Gratis o sin modalidad', () {
      expect(validador.validarPrecio(Modalidad.intercambio, ''), isNull);
      expect(validador.validarPrecio(Modalidad.gratis, 'abc'), isNull);
      expect(validador.validarPrecio(null, ''), isNull);
    });
  });

  group('leerPrecio', () {
    test('entiende signo de pesos, coma decimal y separador de miles', () {
      expect(validador.leerPrecio('150'), 150);
      expect(validador.leerPrecio(r'$150.5'), 150.5);
      expect(validador.leerPrecio('150,50'), 150.5);
      expect(validador.leerPrecio('1,200'), 1200);
      expect(validador.leerPrecio('1,200.75'), 1200.75);
      expect(validador.leerPrecio('12 345'), 12345);
      expect(validador.leerPrecio('100,000'), 100000);
    });

    test('devuelve null si no es un precio', () {
      expect(validador.leerPrecio(''), isNull);
      expect(validador.leerPrecio('cien'), isNull);
      expect(validador.leerPrecio('123456789'), isNull);
      // No cabe en la columna numeric(10, 2) de la base de datos.
      expect(validador.leerPrecio('999,999,999'), isNull);
    });
  });

  group('validarFoto y validarFotos', () {
    test('aceptan JPG y PNG de hasta 5 MB', () {
      expect(validador.validarFoto(fotoJpg()), isNull);
      expect(validador.validarFoto(fotoPng()), isNull);
      expect(validador.validarFotos([fotoJpg(), fotoPng()]), isNull);
    });

    test('Escenario 4: una foto de más de 5 MB se rechaza', () {
      final Failure? error = validador.validarFoto(fotoMayorA5MB());
      expect(error, isA<FotoArticuloDemasiadoGrandeFailure>());
      expect(error!.mensaje, 'Cada foto puede pesar máximo 5 MB.');
      expect(validador.validarFotos([fotoJpg(), fotoMayorA5MB()]), error.mensaje);
    });

    test('un archivo que no es JPG ni PNG se rechaza aunque diga .jpg', () {
      expect(validador.validarFoto(fotoGif()), isA<FotoFormatoInvalidoFailure>());
    });

    test('Escenario 5: sin fotos pide agregar al menos una; más de 5 no se permite', () {
      expect(validador.validarFotos([]), 'Agrega al menos una foto.');
      expect(
        validador.validarFotos(List.generate(6, (_) => fotoJpg())),
        'Puedes agregar máximo 5 fotos.',
      );
    });
  });

  group('validar (formulario completo)', () {
    test('Escenario 1: un borrador correcto no tiene errores', () {
      expect(validador.validar(borrador()), isEmpty);
      expect(
        validador.validar(borrador(modalidad: Modalidad.venta, precioTexto: '250')),
        isEmpty,
      );
    });

    test('Escenario 5: marca cada campo obligatorio vacío', () {
      final Map<CampoPublicacion, String> errores = validador.validar(borrador(
        titulo: '',
        descripcion: '',
        categoria: null,
        modalidad: null,
        fotos: [],
      ));

      expect(errores.keys, containsAll(<CampoPublicacion>[
        CampoPublicacion.titulo,
        CampoPublicacion.descripcion,
        CampoPublicacion.categoria,
        CampoPublicacion.modalidad,
        CampoPublicacion.fotos,
      ]));
      expect(errores.containsKey(CampoPublicacion.precio), isFalse);
    });

    test('Escenario 2: en Venta sin precio solo se marca el precio', () {
      final Map<CampoPublicacion, String> errores =
          validador.validar(borrador(modalidad: Modalidad.venta));

      expect(errores, {CampoPublicacion.precio: PublicacionValidator.mensajePrecioVacio});
    });
  });
}
