import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/email_validator.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Pantalla 2 - Registro.
/// Componentes: campo de correo institucional, campo de contraseña, campo
/// de confirmación de contraseña, botón "Registrarse", enlace "¿Ya tienes
/// cuenta? Inicia sesión", mensaje de error para dominio no institucional.
class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmarController = TextEditingController();
  final EmailValidator _validadorCorreo = const EmailValidator();

  String? _errorCorreo;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _registrar() {
    // Validación de dominio institucional en vivo, antes de llamar al Cubit
    // (Escenario 2 de HU-01: registro rechazado por correo no institucional).
    setState(() => _errorCorreo = _validadorCorreo.validar(_correoController.text));
    if (_errorCorreo != null) return;

    context.read<AuthCubit>().registrar(
          correo: _correoController.text,
          contrasena: _contrasenaController.text,
          confirmarContrasena: _confirmarController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistroExitoso) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.confirmacionRegistro);
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _correoController,
                  label: 'Correo institucional (@alumno.utsjr.edu.mx)',
                  tipoTeclado: TextInputType.emailAddress,
                  textoError: _errorCorreo,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _contrasenaController,
                  label: 'Contraseña',
                  esContrasena: true,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmarController,
                  label: 'Confirmar contraseña',
                  esContrasena: true,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  texto: 'Registrarse',
                  cargando: cargando,
                  onPressed: _registrar,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: cargando ? null : () => Navigator.of(context).pop(),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
