import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';

/// Pantalla 3 - Confirmación de registro.
/// Componentes: ícono de correo enviado, mensaje de confirmación, botón
/// "Ir a iniciar sesión".
class ConfirmacionRegistroPage extends StatelessWidget {
  const ConfirmacionRegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppMedidas.margen),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: AppColores.acentoSuave,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 52,
                  color: AppColores.primario,
                ),
              ),
              const SizedBox(height: 24),
              Text('Revisa tu correo', style: AppTexto.titulo(size: 24)),
              const SizedBox(height: 8),
              Text(
                'Te enviamos un enlace a tu correo institucional. Confírmalo antes de '
                'iniciar sesión.',
                textAlign: TextAlign.center,
                style: AppTexto.cuerpo(),
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
      ),
    );
  }
}
