import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/email_validator.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Pantalla 2 - Registro.
/// Componentes: campo de correo institucional, campo de contraseña, campo
/// de confirmación de contraseña, botón "Crear cuenta", enlace "¿Ya tienes
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
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistroExitoso) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.confirmacionRegistro);
          }
          if (state is AuthError) {
            mostrarMensaje(context, state.failure.mensaje, esError: true);
          }
        },
        builder: (context, state) {
          final bool cargando = state is AuthCargando;
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BarraSuperior(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppMedidas.margen,
                      8,
                      AppMedidas.margen,
                      AppMedidas.margen,
                    ),
                    children: [
                      Text('Crea tu cuenta', style: AppTexto.titulo()),
                      const SizedBox(height: 8),
                      Text(
                        'Solo para la comunidad UTSJR. Usa tu correo que termina en '
                        '@utsjr.edu.mx',
                        style: AppTexto.cuerpo(),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _correoController,
                        label: 'Correo institucional',
                        hint: 'tu.nombre@utsjr.edu.mx',
                        tipoTeclado: TextInputType.emailAddress,
                        textoError: _errorCorreo,
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        controller: _contrasenaController,
                        label: 'Contraseña',
                        esContrasena: true,
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        controller: _confirmarController,
                        label: 'Confirmar contraseña',
                        esContrasena: true,
                      ),
                      const SizedBox(height: 18),
                      const _AvisoRegistro(),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        texto: 'Crear cuenta',
                        cargando: cargando,
                        onPressed: _registrar,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¿Ya tienes cuenta?', style: AppTexto.cuerpo()),
                      EnlaceTexto(
                        texto: 'Inicia sesión',
                        onPressed: cargando ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AvisoRegistro extends StatelessWidget {
  const _AvisoRegistro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColores.acentoSuave,
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: AppColores.primario, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mínimo 8 caracteres. Te enviaremos un correo para confirmar tu cuenta.',
              style: AppTexto.cuerpo(size: 13, color: AppColores.texto),
            ),
          ),
        ],
      ),
    );
  }
}
