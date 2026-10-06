import 'package:flutter/widgets.dart';

/// Keys de los widgets importantes de las pantallas de perfil.
/// Las pruebas buscan los widgets por estas Keys, así el diseño visual
/// puede cambiar sin romper pruebas. Si rediseñas, CONSERVA las Keys.
class PerfilKeys {
  PerfilKeys._();

  static const Key nombreField = Key('perfil_nombre_field');
  static const Key divisionSelector = Key('perfil_division_selector');
  static const Key carreraSelector = Key('perfil_carrera_selector');
  static const Key avatar = Key('perfil_avatar');
  static const Key elegirFotoBoton = Key('perfil_elegir_foto_boton');
  static const Key quitarFotoBoton = Key('perfil_quitar_foto_boton');
  static const Key guardarBoton = Key('perfil_guardar_boton');
  static const Key reintentarBoton = Key('perfil_reintentar_boton');
  static const Key editarBoton = Key('perfil_editar_boton');
  static const Key cerrarSesionBoton = Key('perfil_cerrar_sesion_boton');
  static const Key tarjetaPerfil = Key('perfil_tarjeta');
  static const Key cargando = Key('perfil_cargando');
  static const Key errorCarga = Key('perfil_error_carga');
}
