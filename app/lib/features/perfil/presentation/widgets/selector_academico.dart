import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/carrera.dart';
import '../../domain/entities/division.dart';
import '../cubit/perfil_cubit.dart';
import '../cubit/perfil_state.dart';
import '../perfil_keys.dart';

/// Selectores encadenados División → Carrera. Solo dibuja lo que hay en
/// [datos] y avisa al Cubit; la regla "la carrera pertenece a la división"
/// vive en el Cubit y en los casos de uso.
///
/// TODO(diseño): selector final de división/carrera (bottom sheet, chips,
/// buscador, etc.). Conserva las Keys de PerfilKeys.
class SelectorAcademico extends StatelessWidget {
  const SelectorAcademico({super.key, required this.datos, this.habilitado = true});

  final PerfilDatos datos;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final PerfilCubit cubit = context.read<PerfilCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'División',
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Division>(
              key: PerfilKeys.divisionSelector,
              isExpanded: true,
              isDense: true,
              value: datos.divisionSeleccionada,
              hint: const Text('Selecciona tu división'),
              items: datos.catalogo
                  .map((d) => DropdownMenuItem<Division>(value: d, child: Text(d.nombre)))
                  .toList(),
              onChanged: habilitado ? cubit.seleccionarDivision : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Carrera',
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Carrera>(
              key: PerfilKeys.carreraSelector,
              isExpanded: true,
              isDense: true,
              value: datos.carreraSeleccionada,
              hint: Text(
                datos.divisionSeleccionada == null
                    ? 'Primero elige una división'
                    : 'Selecciona tu carrera',
              ),
              items: datos.carrerasDisponibles
                  .map((c) => DropdownMenuItem<Carrera>(value: c, child: Text(c.nombre)))
                  .toList(),
              onChanged: habilitado && datos.divisionSeleccionada != null
                  ? cubit.seleccionarCarrera
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
