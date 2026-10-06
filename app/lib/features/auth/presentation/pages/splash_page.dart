import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/resolver_destino_inicial.dart';
import '../navegacion_inicial.dart';

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

    // HU-02: sin sesión → Login; perfil incompleto → Completar perfil;
    // perfil completo → Feed. La regla vive en ResolverDestinoInicial.
    final DestinoInicial destino =
        await ResolverDestinoInicial(context.read<AuthRepository>())();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(rutaParaDestino(destino));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.primario,
      body: Stack(
        children: [
          // Círculos decorativos del diseño.
          Positioned(
            top: -90,
            right: -140,
            child: _Circulo(diametro: 320, color: AppColores.sobrePrimario.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: -60,
            left: -110,
            child: _Circulo(diametro: 260, color: AppColores.acento.withValues(alpha: 0.18)),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(ancho: 260),
                  const SizedBox(height: 20),
                  Text(
                    'Compra, vende e intercambia\ndentro de tu universidad',
                    textAlign: TextAlign.center,
                    style: AppTexto.cuerpo(
                      color: AppColores.sobrePrimario.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColores.acento,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Text(
              'Universidad Tecnológica de San Juan del Río',
              textAlign: TextAlign.center,
              style: AppTexto.cuerpo(
                size: 12,
                color: AppColores.sobrePrimario.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  const _Circulo({required this.diametro, required this.color});

  final double diametro;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
