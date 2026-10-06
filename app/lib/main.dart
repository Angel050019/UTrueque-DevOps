import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/network/network_info.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/cerrar_sesion.dart';
import 'features/auth/domain/usecases/iniciar_sesion.dart';
import 'features/auth/domain/usecases/registrar_usuario.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/confirmacion_registro_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/registro_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/feed/presentation/pages/feed_placeholder_page.dart';
import 'features/perfil/data/datasources/perfil_remote_datasource.dart';
import 'features/perfil/data/repositories/perfil_repository_impl.dart';
import 'features/perfil/domain/repositories/perfil_repository.dart';
import 'features/perfil/domain/usecases/actualizar_perfil.dart';
import 'features/perfil/domain/usecases/obtener_catalogo_academico.dart';
import 'features/perfil/domain/usecases/obtener_perfil.dart';
import 'features/perfil/presentation/cubit/perfil_cubit.dart';
import 'features/perfil/presentation/pages/completar_perfil_page.dart';
import 'features/perfil/presentation/pages/editar_perfil_page.dart';
import 'features/perfil/presentation/pages/mi_perfil_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La URL y la anon key de Supabase se inyectan en tiempo de compilación
  // vía --dart-define (nunca se hardcodean ni se suben al repo):
  //   flutter run \
  //     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  //     --dart-define=SUPABASE_ANON_KEY=xxxxx
  // En CI, estos valores viven en GitHub Secrets.
  await Supabase.initialize(
    url: const String.fromEnvironment(AppConstants.supabaseUrlEnvKey),
    publishableKey: const String.fromEnvironment(AppConstants.supabaseAnonKeyEnvKey),
  );

  runApp(const UTruequeApp());
}

class UTruequeApp extends StatelessWidget {
  const UTruequeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Composición manual de dependencias para HU-01 (sin service locator
    // externo todavía; se evaluará get_it si el árbol crece en próximos
    // sprints).
    final AuthRemoteDataSource dataSource =
        AuthRemoteDataSourceImpl(Supabase.instance.client);
    final AuthRepository authRepository = AuthRepositoryImpl(dataSource);
    final NetworkInfo networkInfo = NetworkInfoImpl(Connectivity());
    final PerfilRepository perfilRepository =
        PerfilRepositoryImpl(PerfilRemoteDataSourceImpl(Supabase.instance.client));

    // Factory Method: cada pantalla de perfil recibe su propio PerfilCubit.
    PerfilCubit crearPerfilCubit() => PerfilCubit(
          obtenerPerfil: ObtenerPerfil(perfilRepository, networkInfo),
          obtenerCatalogo: ObtenerCatalogoAcademico(perfilRepository, networkInfo),
          actualizarPerfil: ActualizarPerfil(perfilRepository, networkInfo),
        );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<PerfilRepository>.value(value: perfilRepository),
      ],
      child: BlocProvider(
        create: (_) => AuthCubit(
          registrarUsuario: RegistrarUsuario(authRepository),
          iniciarSesion: IniciarSesion(authRepository, networkInfo),
          cerrarSesion: CerrarSesion(authRepository),
        ),
        child: MaterialApp(
          title: 'UTrueque',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro,
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashPage(),
            AppRoutes.login: (_) => const LoginPage(),
            AppRoutes.registro: (_) => const RegistroPage(),
            AppRoutes.confirmacionRegistro: (_) => const ConfirmacionRegistroPage(),
            AppRoutes.feedPrincipal: (_) => const FeedPlaceholderPage(),
            // HU-02: Perfil Académico
            AppRoutes.completarPerfil: (_) => BlocProvider(
                  create: (_) => crearPerfilCubit()..cargarMiPerfil(),
                  child: const CompletarPerfilPage(),
                ),
            AppRoutes.miPerfil: (_) => BlocProvider(
                  create: (_) => crearPerfilCubit()..cargarMiPerfil(conCatalogo: false),
                  child: const MiPerfilPage(),
                ),
            AppRoutes.editarPerfil: (_) => BlocProvider(
                  create: (_) => crearPerfilCubit()..cargarMiPerfil(),
                  child: const EditarPerfilPage(),
                ),
          },
        ),
      ),
    );
  }
}
