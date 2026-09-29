import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/perfil_cubit.dart';
import '../cubit/perfil_state.dart';
import '../perfil_keys.dart';
import '../widgets/estado_carga_perfil.dart';
import '../widgets/tarjeta_perfil.dart';

/// Pantalla 6 - Mi perfil. Muestra el perfil, permite ir a editarlo y
/// cerrar sesión.
///
/// TODO(diseño): diseño final (acciones en AppBar o menú, secciones).
class MiPerfilPage extends StatelessWidget {
  const MiPerfilPage({super.key});

  Future<void> _irAEditar(BuildContext context) async {
    final PerfilCubit cubit = context.read<PerfilCubit>();
    final Object? cambio = await Navigator.of(context).pushNamed(AppRoutes.editarPerfil);
    if (cambio == true) await cubit.cargarMiPerfil(conCatalogo: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSesionCerrada) {
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.failure.mensaje)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        body: BlocBuilder<PerfilCubit, PerfilState>(
          builder: (context, state) {
            final PerfilDatos? datos = state.datos;
            if (datos == null) {
              if (state is PerfilError) {
                return ErrorCargaPerfil(
                  mensaje: state.mensaje,
                  onReintentar: () =>
                      context.read<PerfilCubit>().cargarMiPerfil(conCatalogo: false),
                );
              }
              return const CargandoPerfil();
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TarjetaPerfil(perfil: datos.perfil),
                const SizedBox(height: 24),
                OutlinedButton(
                  key: PerfilKeys.editarBoton,
                  onPressed: () => _irAEditar(context),
                  child: const Text('Editar perfil'),
                ),
                const SizedBox(height: 8),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) => TextButton(
                    key: PerfilKeys.cerrarSesionBoton,
                    onPressed: authState is AuthCargando
                        ? null
                        : context.read<AuthCubit>().cerrarSesion,
                    child: const Text('Cerrar sesión'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
