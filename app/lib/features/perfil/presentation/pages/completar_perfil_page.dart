import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../cubit/perfil_cubit.dart';
import '../cubit/perfil_state.dart';
import '../widgets/estado_carga_perfil.dart';
import '../widgets/formulario_perfil.dart';

/// Pantalla 5 - Completar perfil (HU-02, Escenario 1).
/// Aparece después del login cuando `perfil_completo` es falso.
/// Al guardar con éxito lleva al Feed.
///
/// TODO(diseño): encabezado de bienvenida ("¡Ya casi!"), pasos, ilustración.
class CompletarPerfilPage extends StatefulWidget {
  const CompletarPerfilPage({super.key});

  @override
  State<CompletarPerfilPage> createState() => _CompletarPerfilPageState();
}

class _CompletarPerfilPageState extends State<CompletarPerfilPage> {
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
      appBar: AppBar(
        title: const Text('Completa tu perfil'),
        automaticallyImplyLeading: false,
      ),
      body: BlocConsumer<PerfilCubit, PerfilState>(
        listener: (context, state) {
          if (state is PerfilCargado && !_nombreInicializado) {
            _nombreInicializado = true;
            _nombreController.text = state.datos.perfil.nombreMostrar ?? '';
          }
          if (state is PerfilGuardado) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.feedPrincipal, (route) => false);
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
            textoBoton: 'Guardar y continuar',
          );
        },
      ),
    );
  }
}
