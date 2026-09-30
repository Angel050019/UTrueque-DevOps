import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

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
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoginExitoso) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.feedPrincipal);
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.mensaje)),
            );
          }
        },
        builder: (context, state) {
          final bool cargando = state is AuthCargando;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _correoController,
                  label: 'Correo institucional',
                  tipoTeclado: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _contrasenaController,
                  label: 'Contraseña',
                  esContrasena: true,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  texto: 'Iniciar sesión',
                  cargando: cargando,
                  onPressed: _iniciarSesion,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Recuperación de contraseña: fuera de alcance de HU-01,
                    // se implementará en un sprint posterior.
                  },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
                TextButton(
                  onPressed: cargando
                      ? null
                      : () => Navigator.of(context).pushNamed(AppRoutes.registro),
                  child: const Text('¿No tienes cuenta? Crear cuenta'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
