import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/foto_perfil.dart';
import '../perfil_keys.dart';

/// Foto de perfil: muestra la foto recién elegida, la guardada o las
/// iniciales del nombre. Con [mostrarInsignia] dibuja el botón verde de
/// cámara que indica "cambiar foto".
class AvatarPerfil extends StatelessWidget {
  const AvatarPerfil({
    super.key,
    this.fotoUrl,
    this.fotoNueva,
    this.nombre,
    this.radio = 52,
    this.mostrarInsignia = false,
    this.onTap,
  });

  final String? fotoUrl;
  final FotoPerfil? fotoNueva;
  final String? nombre;
  final double radio;
  final bool mostrarInsignia;
  final VoidCallback? onTap;

  static String iniciales(String? nombre) {
    final List<String> partes =
        (nombre ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '';
    final String primera = partes.first.substring(0, 1);
    final String segunda = partes.length > 1 ? partes[1].substring(0, 1) : '';
    return '$primera$segunda'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imagen;
    if (fotoNueva != null) {
      imagen = MemoryImage(fotoNueva!.bytes);
    } else if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      imagen = NetworkImage(fotoUrl!);
    }
    final String letras = iniciales(nombre);

    final Widget circulo = Container(
      width: radio * 2,
      height: radio * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColores.primarioSuave,
        border: Border.all(color: AppColores.superficie, width: 4),
        image: imagen == null ? null : DecorationImage(image: imagen, fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: imagen != null
          ? null
          : letras.isEmpty
              ? Icon(Icons.person_rounded, size: radio, color: AppColores.primario)
              : Text(
                  letras,
                  style: AppTexto.subtitulo(size: radio * 0.65, color: AppColores.primario),
                ),
    );

    return GestureDetector(
      key: PerfilKeys.avatar,
      onTap: onTap,
      child: SizedBox(
        width: radio * 2,
        height: radio * 2,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            circulo,
            if (mostrarInsignia)
              Positioned(
                right: -2,
                bottom: 0,
                child: Container(
                  width: radio * 0.66,
                  height: radio * 0.66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColores.acento,
                    border: Border.all(color: AppColores.superficie, width: 3),
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    size: radio * 0.32,
                    color: AppColores.primario,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
