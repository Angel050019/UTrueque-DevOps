import '../../../core/routes/app_routes.dart';
import '../domain/usecases/resolver_destino_inicial.dart';

/// Traduce el [DestinoInicial] (regla de negocio) a una ruta de la app.
/// Lo usan Splash y Login para respetar la regla de HU-02.
String rutaParaDestino(DestinoInicial destino) => switch (destino) {
      DestinoInicial.login => AppRoutes.login,
      DestinoInicial.completarPerfil => AppRoutes.completarPerfil,
      DestinoInicial.feed => AppRoutes.feedPrincipal,
    };
