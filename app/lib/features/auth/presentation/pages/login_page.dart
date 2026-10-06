import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/usecases/resolver_destino_inicial.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../navegacion_inicial.dart';

/// Pantalla 4 - Inicio de sesión (Login).
/// Componentes: campo de correo, campo de contraseña, botón "Iniciar
/// sesión", enlace "¿Olvidaste tu contraseña?", enlace "Crear cuenta",
/// alerta de sin conexión (Escenario 3 de HU-01).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  void _iniciarSesion() {
    context.read<AuthCubit>().iniciarSesion(
          correo: _correoController.text,
          contrasena: _contrasenaController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoginExitoso) {
            // HU-02: perfil incompleto → "Completar perfil"; completo → Feed.
            Navigator.of(context).pushReplacementNamed(
              rutaParaDestino(DestinoInicial.desde(state.usuario)),
            );
          }
          if (state is AuthError) {
            mostrarMensaje(context, state.failure.mensaje, esError: true);
          }
        },
        builder: (context, state) {
          final bool cargando = state is AuthCargando;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _EncabezadoLogin(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppMedidas.margen,
                          32,
                          AppMedidas.margen,
                          AppMedidas.margen,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _correoController,
                              label: 'Correo institucional',
                              hint: 'tu.nombre@utsjr.edu.mx',
                              tipoTeclado: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 18),
                            AppTextField(
                              controller: _contrasenaController,
                              label: 'Contraseña',
                              esContrasena: true,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: EnlaceTexto(
                                texto: '¿Olvidaste tu contraseña?',
                                // Recuperación de contraseña: fuera de alcance
                                // de HU-01, se implementará en un sprint posterior.
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              texto: 'Iniciar sesión',
                              cargando: cargando,
                              onPressed: _iniciarSesion,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¿No tienes cuenta?', style: AppTexto.cuerpo()),
                      EnlaceTexto(
                        texto: 'Crear cuenta',
                        onPressed: cargando
                            ? null
                            : () => Navigator.of(context).pushNamed(AppRoutes.registro),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EncabezadoLogin extends StatelessWidget {
  const _EncabezadoLogin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColores.primario,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        28,
        MediaQuery.paddingOf(context).top + 32,
        28,
        36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(ancho: 160),
          const SizedBox(height: 20),
          Text('¡Hola de nuevo!', style: AppTexto.titulo(color: AppColores.sobrePrimario)),
          const SizedBox(height: 4),
          Text(
            'Inicia sesión con tu correo institucional',
            style: AppTexto.cuerpo(color: AppColores.sobrePrimario.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}
