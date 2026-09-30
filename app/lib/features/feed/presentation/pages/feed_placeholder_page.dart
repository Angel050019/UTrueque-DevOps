import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

/// Placeholder temporal del Feed principal.
/// El Feed real (HU-05) se implementará en el Sprint 2; esta pantalla solo
/// confirma que el flujo de login/registro de HU-01 llega a buen término.
class FeedPlaceholderPage extends StatelessWidget {
  const FeedPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repositorio = context.read<AuthRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await repositorio.cerrarSesion();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Sesión iniciada como ${repositorio.usuarioActual?.correo ?? ''}.\n'
          'El Feed real llega en el Sprint 2 (HU-05).',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
