import 'package:flutter/material.dart';

import '../../domain/entities/foto_perfil.dart';
import '../perfil_keys.dart';

/// Foto de perfil: muestra la foto recién elegida, la guardada o un ícono.
///
/// TODO(diseño): avatar final (tamaño, borde, placeholder con iniciales,
/// indicador de "cambiar foto", estado de carga de la imagen).
class AvatarPerfil extends StatelessWidget {
  const AvatarPerfil({super.key, this.fotoUrl, this.fotoNueva, this.radio = 48});

  final String? fotoUrl;
  final FotoPerfil? fotoNueva;
  final double radio;

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imagen;
    if (fotoNueva != null) {
      imagen = MemoryImage(fotoNueva!.bytes);
    } else if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      imagen = NetworkImage(fotoUrl!);
    }
    return CircleAvatar(
      key: PerfilKeys.avatar,
      radius: radio,
      backgroundImage: imagen,
      child: imagen == null ? Icon(Icons.person, size: radio) : null,
    );
  }
}
