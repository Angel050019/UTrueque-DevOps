import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/categoria.dart';
import '../publicacion_keys.dart';

/// Lista desplegable de categorías con el estilo de los campos de texto.
/// El borde se pone rojo si [error] no es null.
class SelectorCategoria extends StatelessWidget {
  const SelectorCategoria({
    super.key,
    required this.categorias,
    required this.seleccionada,
    required this.onChanged,
    this.error,
    this.habilitado = true,
  });

  final List<Categoria> categorias;
  final Categoria? seleccionada;
  final ValueChanged<Categoria?> onChanged;
  final String? error;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Categoría', style: AppTexto.etiqueta()),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColores.superficie,
            borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
            border: Border.all(
              color: error != null ? AppColores.error : AppColores.borde,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Categoria>(
                key: PublicacionKeys.categoriaSelector,
                isExpanded: true,
                value: seleccionada,
                dropdownColor: AppColores.superficie,
                borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                icon: const Icon(Icons.expand_more_rounded, color: AppColores.textoSecundario),
                hint: Text('¿Qué tipo de artículo es?', style: AppTexto.cuerpo()),
                style: AppTexto.cuerpo(color: AppColores.texto),
                items: [
                  for (final Categoria categoria in categorias)
                    DropdownMenuItem<Categoria>(value: categoria, child: Text(categoria.nombre)),
                ],
                onChanged: habilitado ? onChanged : null,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: AppTexto.cuerpo(size: 12, color: AppColores.error)),
        ],
      ],
    );
  }
}
