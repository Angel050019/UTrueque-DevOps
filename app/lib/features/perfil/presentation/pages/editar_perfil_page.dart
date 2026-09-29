import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/perfil_cubit.dart';
import '../cubit/perfil_state.dart';
import '../widgets/estado_carga_perfil.dart';
import '../widgets/formulario_perfil.dart';

/// Pantalla 7 - Editar perfil (HU-02, Escenario 4).
/// Al guardar con éxito regresa a "Mi perfil" devolviendo `true` para que
/// esa pantalla se recargue.
///
/// TODO(diseño): diseño final de la pantalla de edición.
class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final TextEditingController _nombreController = TextEditingController();
  bool _nombreInicializado = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: BlocConsumer<PerfilCubit, PerfilState>(
        listener: (context, state) {
          if (state is PerfilCargado && !_nombreInicializado) {
            _nombreInicializado = true;
            _nombreController.text = state.datos.perfil.nombreMostrar ?? '';
          }
          if (state is PerfilGuardado) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perfil actualizado.')),
            );
            Navigator.of(context).pop(true);
          }
          if (state is PerfilError && state.datos != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.mensaje)));
          }
        },
        builder: (context, state) {
          final PerfilDatos? datos = state.datos;
          if (datos == null) {
            if (state is PerfilError) {
              return ErrorCargaPerfil(
                mensaje: state.mensaje,
                onReintentar: context.read<PerfilCubit>().cargarMiPerfil,
              );
            }
            return const CargandoPerfil();
          }
          return FormularioPerfil(
            estado: state,
            datos: datos,
            nombreController: _nombreController,
            textoBoton: 'Guardar cambios',
          );
        },
      ),
    );
  }
}
