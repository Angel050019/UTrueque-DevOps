import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/primary_button.dart';

/// Pantalla 3 - Confirmación de registro.
/// Componentes: ícono de correo enviado, mensaje de confirmación, botón
/// "Ir a iniciar sesión".
class ConfirmacionRegistroPage extends StatelessWidget {
  const ConfirmacionRegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 72),
            const SizedBox(height: 24),
            const Text(
              'Revisa tu correo institucional para confirmar tu cuenta antes de iniciar sesión.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              texto: 'Ir a iniciar sesión',
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false),
            ),
          ],
        ),
      ),
    );
  }
}
