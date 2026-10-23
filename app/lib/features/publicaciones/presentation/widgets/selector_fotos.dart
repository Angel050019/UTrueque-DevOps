import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/foto_articulo.dart';
import '../publicacion_keys.dart';

/// Tira horizontal de fotos del artículo: botón para agregar y miniaturas
/// con botón para quitar. La primera foto es la portada.
/// Solo dibuja; las reglas (JPG/PNG, 5 MB, máximo 5) las aplica el Cubit.
class SelectorFotos extends StatelessWidget {
  const SelectorFotos({
    super.key,
    required this.fotos,
    required this.onAgregar,
    required this.onQuitar,
    this.error,
    this.habilitado = true,
  });

  static const double _lado = 96;

  final List<FotoArticulo> fotos;
  final VoidCallback onAgregar;
  final ValueChanged<int> onQuitar;
  final String? error;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final bool caben = fotos.length < AppConstants.fotosPorPublicacionMaximo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Fotos del artículo', style: AppTexto.etiqueta()),
        const SizedBox(height: 4),
        Text(
          '${fotos.length}/${AppConstants.fotosPorPublicacionMaximo} · JPG o PNG · '
          'máx. 5 MB cada una · la primera es la portada',
          style: AppTexto.cuerpo(size: 12),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: _lado,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (caben)
                _BotonAgregar(
                  lado: _lado,
                  conError: error != null,
                  onTap: habilitado ? onAgregar : null,
                ),
              for (int i = 0; i < fotos.length; i++)
                _Miniatura(
                  foto: fotos[i],
                  indice: i,
                  lado: _lado,
                  onQuitar: habilitado ? () => onQuitar(i) : null,
                ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            key: PublicacionKeys.errorFotos,
            style: AppTexto.cuerpo(size: 12, color: AppColores.error),
          ),
        ],
      ],
    );
  }
}

class _BotonAgregar extends StatelessWidget {
  const _BotonAgregar({required this.lado, required this.conError, required this.onTap});

  final double lado;
  final bool conError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: AppColores.primarioSuave,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
          side: BorderSide(
            color: conError ? AppColores.error : AppColores.primario.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: InkWell(
          key: PublicacionKeys.agregarFotoBoton,
          borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
          onTap: onTap,
          child: SizedBox(
            width: lado,
            height: lado,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_a_photo_rounded, color: AppColores.primario),
                const SizedBox(height: 6),
                Text('Agregar', style: AppTexto.etiqueta(color: AppColores.primario)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({
    required this.foto,
    required this.indice,
    required this.lado,
    required this.onQuitar,
  });

  final FotoArticulo foto;
  final int indice;
  final double lado;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: lado,
        height: lado,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                child: Image.memory(foto.bytes, fit: BoxFit.cover, gaplessPlayback: true),
              ),
            ),
            if (indice == 0)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColores.acento,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Portada',
                    style: AppTexto.cuerpo(size: 11, color: AppColores.primario, peso: FontWeight.w600),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: AppColores.texto.withValues(alpha: 0.65),
                shape: const CircleBorder(),
                child: InkWell(
                  key: PublicacionKeys.quitarFoto(indice),
                  customBorder: const CircleBorder(),
                  onTap: onQuitar,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColores.sobrePrimario),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
