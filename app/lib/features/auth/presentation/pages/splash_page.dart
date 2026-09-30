import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../domain/repositories/auth_repository.dart';

/// Pantalla 1 - Splash (carga inicial).
/// Verifica en segundo plano si hay una sesión activa guardada y
/// redirige a Feed principal o a Inicio de sesión según corresponda.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarSesion());
  }

  Future<void> _verificarSesion() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final AuthRepository repositorio = context.read<AuthRepository>();
    final bool haySesionActiva = repositorio.usuarioActual != null;

    Navigator.of(context).pushReplacementNamed(
      haySesionActiva ? AppRoutes.feedPrincipal : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, size: 72),
            SizedBox(height: 16),
            Text('UTrueque', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
