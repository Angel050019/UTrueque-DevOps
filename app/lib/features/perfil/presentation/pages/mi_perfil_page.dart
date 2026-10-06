import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/perfil.dart';
import '../cubit/perfil_cubit.dart';
import '../cubit/perfil_state.dart';
import '../perfil_keys.dart';
import '../widgets/avatar_perfil.dart';
import '../widgets/estado_carga_perfil.dart';
import '../widgets/tarjeta_perfil.dart';

/// Pantalla 6 - Mi perfil. Muestra el perfil, permite ir a editarlo y
/// cerrar sesión.
class MiPerfilPage extends StatelessWidget {
  const MiPerfilPage({super.key});

  static const double _altoEncabezado = 150;
  static const double _radioAvatar = 52;

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
          mostrarMensaje(context, state.failure.mensaje, esError: true);
        }
      },
      child: Scaffold(
        body: BlocBuilder<PerfilCubit, PerfilState>(
          builder: (context, state) {
            final PerfilDatos? datos = state.datos;
            if (datos == null) {
              return SafeArea(
                child: Column(
                  children: [
                    const BarraSuperior(titulo: 'Mi perfil'),
                    Expanded(
                      child: state is PerfilError
                          ? ErrorCargaPerfil(
                              mensaje: state.mensaje,
                              onReintentar: () =>
                                  context.read<PerfilCubit>().cargarMiPerfil(conCatalogo: false),
                            )
                          : const CargandoPerfil(),
                    ),
                  ],
                ),
              );
            }
            return _contenido(context, datos.perfil);
          },
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, Perfil perfil) {
    final String? correo = context.read<AuthRepository>().usuarioActual?.correo;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Encabezado azul con el avatar encimado.
              SizedBox(
                height: _altoEncabezado + _radioAvatar + 8,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: _altoEncabezado,
                      color: AppColores.primario,
                      child: const SafeArea(
                        bottom: false,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: BarraSuperior(titulo: 'Mi perfil', claro: true),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: _altoEncabezado - _radioAvatar,
                      child: Center(
                        child: AvatarPerfil(
                          fotoUrl: perfil.fotoUrl,
                          nombre: perfil.nombreMostrar,
                          radio: _radioAvatar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppMedidas.margen,
                  12,
                  AppMedidas.margen,
                  AppMedidas.margen,
                ),
                child: Column(
                  children: [
                    Text(
                      perfil.nombreMostrar ?? 'Sin nombre',
                      textAlign: TextAlign.center,
                      style: AppTexto.titulo(size: 22),
                    ),
                    if (correo != null) ...[
                      const SizedBox(height: 2),
                      Text(correo, style: AppTexto.cuerpo(size: 14)),
                    ],
                    if (perfil.divisionNombre != null) ...[
                      const SizedBox(height: 12),
                      EtiquetaPerfil(texto: perfil.divisionNombre!),
                    ],
                    const SizedBox(height: 20),
                    TarjetaPerfil(perfil: perfil),
                    const SizedBox(height: 14),
                    const _PublicacionesVacias(),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 8, AppMedidas.margen, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SecondaryButton(
                  key: PerfilKeys.editarBoton,
                  texto: 'Editar perfil',
                  onPressed: () => _irAEditar(context),
                ),
                const SizedBox(height: 4),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) => TextButton.icon(
                    key: PerfilKeys.cerrarSesionBoton,
                    onPressed: authState is AuthCargando
                        ? null
                        : context.read<AuthCubit>().cerrarSesion,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColores.error,
                      textStyle: AppTexto.subtitulo(size: 15),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Cerrar sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PublicacionesVacias extends StatelessWidget {
  const _PublicacionesVacias();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColores.primarioSuave,
        borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
      ),
      child: Column(
        children: [
          Text(
            'Aún no tienes publicaciones',
            style: AppTexto.subtitulo(size: 14, color: AppColores.primario),
          ),
          const SizedBox(height: 4),
          Text(
            'Muy pronto podrás publicar libros, calculadoras y más.',
            textAlign: TextAlign.center,
            style: AppTexto.cuerpo(size: 13),
          ),
        ],
      ),
    );
  }
}
