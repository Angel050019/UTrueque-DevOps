import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/perfil.dart';
import '../perfil_keys.dart';

/// Datos académicos del perfil en modo lectura (Mi perfil / perfil de otro
/// estudiante).
class TarjetaPerfil extends StatelessWidget {
  const TarjetaPerfil({super.key, required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: PerfilKeys.tarjetaPerfil,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información académica', style: AppTexto.subtitulo(size: 15)),
          const SizedBox(height: 14),
          _Dato(titulo: 'División', valor: perfil.divisionNombre ?? 'Sin división'),
          const SizedBox(height: 12),
          _Dato(titulo: 'Carrera', valor: perfil.carreraNombre ?? 'Sin carrera'),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: AppTexto.cuerpo(size: 12)),
        const SizedBox(height: 2),
        Text(
          valor,
          style: AppTexto.cuerpo(color: AppColores.texto, peso: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Etiqueta redondeada (división o carrera).
class EtiquetaPerfil extends StatelessWidget {
  const EtiquetaPerfil({super.key, required this.texto, this.acento = false});

  final String texto;
  final bool acento;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: acento ? AppColores.acentoSuave : AppColores.primarioSuave,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: AppTexto.cuerpo(size: 12, color: AppColores.primario, peso: FontWeight.w500),
      ),
    );
  }
}
