import 'package:flutter/services.dart';

import '../utils/caracteres_permitidos.dart';

/// SEGURIDAD: filtros de escritura de cada campo. No dejan teclear ni pegar
/// caracteres que no están en la lista de permitidos
/// ([CaracteresPermitidos]). Los validadores y la base de datos vuelven a
/// revisar el texto completo antes de guardarlo.
class FiltrosTexto {
  FiltrosTexto._();

  static final List<TextInputFormatter> titulo = [
    FilteringTextInputFormatter.allow(CaracteresPermitidos.caracterTitulo),
  ];

  static final List<TextInputFormatter> descripcion = [
    FilteringTextInputFormatter.allow(CaracteresPermitidos.caracterDescripcion),
  ];

  static final List<TextInputFormatter> nombre = [
    FilteringTextInputFormatter.allow(CaracteresPermitidos.caracterNombre),
  ];

  static final List<TextInputFormatter> busqueda = [
    FilteringTextInputFormatter.allow(CaracteresPermitidos.caracterBusqueda),
  ];

  static final List<TextInputFormatter> precio = [
    FilteringTextInputFormatter.allow(CaracteresPermitidos.caracterPrecio),
  ];

  static final List<TextInputFormatter> correo = [
    FilteringTextInputFormatter.allow(CaracteresPermitidos.caracterCorreo),
  ];
}
