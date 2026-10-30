import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/core/routes/app_routes.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/presentation/pages/publicar_articulo_page.dart';

import '../fixtures.dart';

/// Regresión de HU-06: "Editar publicación" se congelaba al abrirse.
///
/// La ruta se registra igual que en main.dart, en el mapa `routes` de
/// MaterialApp (que crea rutas `MaterialPageRoute<dynamic>`). Antes se pedía
/// con `pushNamed<Publicacion>` y eso lanzaba un error de tipos.
void main() {
  const Key abrir = Key('abrir_editar');
  const Key guardar = Key('guardar_cambios');

  /// [devuelve] es lo que regresa la pantalla de edición al cerrarse.
  Widget app({required ValueChanged<Publicacion?> alRegresar, Object? Function(Publicacion)? devuelve}) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{
        AppRoutes.editarPublicacion: (context) {
          final Publicacion recibida = ModalRoute.of(context)!.settings.arguments! as Publicacion;
          return Scaffold(
            body: TextButton(
              key: guardar,
              onPressed: () => Navigator.of(context).pop(devuelve == null ? recibida : devuelve(recibida)),
              child: Text('Editando ${recibida.id}'),
            ),
          );
        },
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: abrir,
            onPressed: () async => alRegresar(await PublicarArticuloPage.editar(context, miPublicacion('p1'))),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
  }

  testWidgets('abre "Editar publicación" desde el mapa de rutas sin error de tipos', (tester) async {
    // ARRANGE
    await tester.pumpWidget(app(alRegresar: (_) {}));

    // ACT
    await tester.tap(find.byKey(abrir));
    await tester.pumpAndSettle();

    // ASSERT
    expect(tester.takeException(), isNull);
    expect(find.text('Editando p1'), findsOneWidget);
  });

  testWidgets('al guardar regresa la publicación editada', (tester) async {
    // ARRANGE
    Publicacion? resultado;
    bool regreso = false;
    await tester.pumpWidget(app(
      alRegresar: (p) {
        regreso = true;
        resultado = p;
      },
      devuelve: (p) => miPublicacion(p.id, titulo: 'Calculadora Casio'),
    ));

    // ACT
    await tester.tap(find.byKey(abrir));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(guardar));
    await tester.pumpAndSettle();

    // ASSERT
    expect(regreso, isTrue);
    expect(resultado?.titulo, 'Calculadora Casio');
    expect(tester.takeException(), isNull);
  });

  testWidgets('si regresa sin guardar (o con otra cosa), el resultado es null', (tester) async {
    for (final Object? Function(Publicacion) devuelve in <Object? Function(Publicacion)>[
      (_) => null,
      (_) => 'otra cosa',
    ]) {
      // ARRANGE
      bool regreso = false;
      Publicacion? resultado = miPublicacion('x');
      await tester.pumpWidget(app(
        alRegresar: (p) {
          regreso = true;
          resultado = p;
        },
        devuelve: devuelve,
      ));

      // ACT
      await tester.tap(find.byKey(abrir));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(guardar));
      await tester.pumpAndSettle();

      // ASSERT
      expect(regreso, isTrue);
      expect(resultado, isNull);
    }
  });
}
