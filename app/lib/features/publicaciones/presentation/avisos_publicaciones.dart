import 'dart:async';

import '../domain/entities/publicacion.dart';

/// Un cambio en una publicación: [publicacion] es cómo quedó, o `null` si
/// se borró.
class CambioPublicacion {
  const CambioPublicacion(this.id, this.publicacion);

  final String id;
  final Publicacion? publicacion;
}

/// HU-06, Escenario 14: aviso de que una publicación cambió de estado, se
/// editó o se borró, para que el Feed y "Mis publicaciones" se actualicen
/// sin tener que jalar para actualizar.
///
/// Hay una sola instancia en la app (la crea `main.dart`). Las pantallas que
/// cambian una publicación llaman a [avisar]; las listas escuchan [cambios].
class AvisosPublicaciones {
  final StreamController<CambioPublicacion> _controlador =
      StreamController<CambioPublicacion>.broadcast();

  Stream<CambioPublicacion> get cambios => _controlador.stream;

  void avisar(String id, Publicacion? publicacion) {
    if (!_controlador.isClosed) _controlador.add(CambioPublicacion(id, publicacion));
  }

  Future<void> cerrar() => _controlador.close();
}
