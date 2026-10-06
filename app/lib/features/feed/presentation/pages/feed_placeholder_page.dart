import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/domain/entities/usuario.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

/// Placeholder temporal del Feed principal.
/// El Feed real (HU-05) llega en un sprint posterior; por ahora muestra el
/// saludo, el buscador y los filtros (sin funcionalidad) y da acceso a
/// "Mi perfil" desde el avatar.
class FeedPlaceholderPage extends StatelessWidget {
  const FeedPlaceholderPage({super.key});

  static const List<String> _filtros = ['Todo', 'Libros', 'Calculadoras', 'Batas'];

  @override
  Widget build(BuildContext context) {
    final Usuario? usuario = context.read<AuthRepository>().usuarioActual;
    final String nombre = _primerNombre(usuario);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppMedidas.margen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, $nombre', style: AppTexto.titulo(size: 24)),
                        Text('¿Qué necesitas hoy?', style: AppTexto.cuerpo(size: 14)),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Mi perfil',
                    child: InkWell(
                      key: const Key('feed_mi_perfil_boton'),
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.miPerfil),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColores.primarioSuave,
                        child: Text(
                          _iniciales(nombre),
                          style: AppTexto.subtitulo(size: 15, color: AppColores.primario),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColores.superficie,
                  borderRadius: BorderRadius.circular(AppMedidas.radioBoton),
                  border: Border.all(color: AppColores.borde),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColores.textoSecundario),
                    const SizedBox(width: 10),
                    Text('Busca libros, calculadoras, batas…', style: AppTexto.cuerpo()),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final String filtro in _filtros)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _Filtro(texto: filtro, activo: filtro == _filtros.first),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: AppColores.primarioSuave,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            size: 56,
                            color: AppColores.primario,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aquí verás las publicaciones',
                          textAlign: TextAlign.center,
                          style: AppTexto.subtitulo(size: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Muy pronto podrás comprar, vender e intercambiar con estudiantes '
                          'de tu división y carrera.',
                          textAlign: TextAlign.center,
                          style: AppTexto.cuerpo(size: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _primerNombre(Usuario? usuario) {
    final String? nombre = usuario?.nombreMostrar;
    if (nombre != null && nombre.trim().isNotEmpty) {
      return nombre.trim().split(' ').first;
    }
    final String correo = usuario?.correo ?? '';
    return correo.contains('@') ? correo.split('@').first : 'estudiante';
  }

  static String _iniciales(String nombre) =>
      nombre.isEmpty ? '?' : nombre.substring(0, 1).toUpperCase();
}

class _Filtro extends StatelessWidget {
  const _Filtro({required this.texto, required this.activo});

  final String texto;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? AppColores.primario : AppColores.superficie,
        borderRadius: BorderRadius.circular(999),
        border: activo ? null : Border.all(color: AppColores.borde),
      ),
      child: Text(
        texto,
        style: AppTexto.cuerpo(
          size: 13,
          peso: FontWeight.w500,
          color: activo ? AppColores.sobrePrimario : AppColores.texto,
        ),
      ),
    );
  }
}
