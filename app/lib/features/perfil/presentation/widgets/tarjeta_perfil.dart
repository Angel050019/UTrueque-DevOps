import 'package:flutter/material.dart';

import '../../domain/entities/perfil.dart';
import '../perfil_keys.dart';
import 'avatar_perfil.dart';

/// Datos del perfil en modo lectura (Mi perfil / perfil de otro estudiante).
///
/// TODO(diseño): tarjeta de perfil final (portada, avatar grande, chips de
/// división/carrera, estadísticas de publicaciones en sprints futuros).
class TarjetaPerfil extends StatelessWidget {
  const TarjetaPerfil({super.key, required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: PerfilKeys.tarjetaPerfil,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AvatarPerfil(fotoUrl: perfil.fotoUrl),
            const SizedBox(height: 16),
            Text(
              perfil.nombreMostrar ?? 'Sin nombre',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(perfil.divisionNombre ?? 'Sin división', textAlign: TextAlign.center),
            Text(perfil.carreraNombre ?? 'Sin carrera', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
