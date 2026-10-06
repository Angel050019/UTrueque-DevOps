import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/domain/entities/usuario.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../perfil/domain/entities/perfil.dart';
import '../../../perfil/domain/repositories/perfil_repository.dart';
import '../../../perfil/presentation/widgets/avatar_perfil.dart';

/// Placeholder temporal del Feed principal.
/// El Feed real (HU-05) llega en un sprint posterior; por ahora muestra el
/// saludo, el buscador y los filtros (sin funcionalidad) y da acceso a
/// "Mi perfil" desde el avatar.
class FeedPlaceholderPage extends StatefulWidget {
  const FeedPlaceholderPage({super.key});

  @override
  State<FeedPlaceholderPage> createState() => _FeedPlaceholderPageState();
}

class _FeedPlaceholderPageState extends State<FeedPlaceholderPage> {
  static const List<String> _filtros = ['Todo', 'Libros', 'Calculadoras', 'Batas'];

  /// Perfil del estudiante (nombre y foto). Mientras carga es null.
  Perfil? _perfil;

  /// Evita mostrar el correo un instante antes de que llegue el nombre.
  bool _cargado = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final Perfil perfil = await context.read<PerfilRepository>().obtenerPerfilPropio();
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // Si falla (por ejemplo, sin internet) se usa el correo como respaldo.
    } finally {
      if (mounted) setState(() => _cargado = true);
    }
  }

  Future<void> _irAMiPerfil() async {
    await Navigator.of(context).pushNamed(AppRoutes.miPerfil);
    // Al regresar se recarga por si el estudiante editó su nombre o foto.
    await _cargarPerfil();
  }

  @override
  Widget build(BuildContext context) {
    final Usuario? usuario = context.read<AuthRepository>().usuarioActual;
    final String nombre = _primerNombre(_perfil?.nombreMostrar, usuario);

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
                        Text(_cargado ? 'Hola, $nombre' : 'Hola', style: AppTexto.titulo(size: 24)),
                        Text('¿Qué necesitas hoy?', style: AppTexto.cuerpo(size: 14)),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Mi perfil',
                    child: InkWell(
                      key: const Key('feed_mi_perfil_boton'),
                      customBorder: const CircleBorder(),
                      onTap: _irAMiPerfil,
                      child: AvatarPerfil(
                        fotoUrl: _perfil?.fotoUrl,
                        nombre: _perfil?.nombreMostrar ?? nombre,
                        radio: 24,
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

  /// Primer nombre del perfil; si aún no carga, el del usuario o el correo.
  static String _primerNombre(String? nombrePerfil, Usuario? usuario) {
    for (final String? nombre in [nombrePerfil, usuario?.nombreMostrar]) {
      if (nombre != null && nombre.trim().isNotEmpty) {
        return nombre.trim().split(RegExp(r'\s+')).first;
      }
    }
    final String correo = usuario?.correo ?? '';
    return correo.contains('@') ? correo.split('@').first : 'estudiante';
  }
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
