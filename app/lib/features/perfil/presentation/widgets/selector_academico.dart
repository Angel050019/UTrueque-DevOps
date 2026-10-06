import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/carrera.dart';
import '../../domain/entities/division.dart';
import '../cubit/perfil_cubit.dart';
import '../cubit/perfil_state.dart';
import '../perfil_keys.dart';

/// Selectores encadenados División → Carrera. Solo dibuja lo que hay en
/// [datos] y avisa al Cubit; la regla "la carrera pertenece a la división"
/// vive en el Cubit y en los casos de uso.
class SelectorAcademico extends StatelessWidget {
  const SelectorAcademico({super.key, required this.datos, this.habilitado = true});

  final PerfilDatos datos;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final PerfilCubit cubit = context.read<PerfilCubit>();
    final bool carreraHabilitada = habilitado && datos.divisionSeleccionada != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CajaSelector<Division>(
          etiqueta: 'División',
          selectorKey: PerfilKeys.divisionSelector,
          valor: datos.divisionSeleccionada,
          pista: 'Selecciona tu división',
          opciones: datos.catalogo,
          textoDe: (d) => d.nombre,
          habilitado: habilitado,
          onChanged: cubit.seleccionarDivision,
        ),
        const SizedBox(height: 16),
        _CajaSelector<Carrera>(
          etiqueta: 'Carrera',
          selectorKey: PerfilKeys.carreraSelector,
          valor: datos.carreraSeleccionada,
          pista: datos.divisionSeleccionada == null
              ? 'Primero elige una división'
              : 'Selecciona tu carrera',
          opciones: datos.carrerasDisponibles,
          textoDe: (c) => c.nombre,
          habilitado: carreraHabilitada,
          onChanged: cubit.seleccionarCarrera,
        ),
      ],
    );
  }
}

/// Selector con el mismo estilo que los campos de texto: etiqueta arriba
/// y caja blanca redondeada. Conserva el `DropdownButton` con su Key para
/// que las pruebas lo sigan encontrando.
class _CajaSelector<T> extends StatelessWidget {
  const _CajaSelector({
    required this.etiqueta,
    required this.selectorKey,
    required this.valor,
    required this.pista,
    required this.opciones,
    required this.textoDe,
    required this.habilitado,
    required this.onChanged,
  });

  final String etiqueta;
  final Key selectorKey;
  final T? valor;
  final String pista;
  final List<T> opciones;
  final String Function(T) textoDe;
  final bool habilitado;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: habilitado ? 1 : 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(etiqueta, style: AppTexto.etiqueta()),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColores.superficie,
              borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
              border: Border.all(color: AppColores.borde, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                key: selectorKey,
                isExpanded: true,
                value: valor,
                borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                dropdownColor: AppColores.superficie,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColores.textoSecundario,
                ),
                hint: Text(pista, style: AppTexto.cuerpo()),
                style: AppTexto.cuerpo(color: AppColores.texto),
                items: opciones
                    .map(
                      (o) => DropdownMenuItem<T>(
                        value: o,
                        child: Text(textoDe(o), overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: habilitado ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
