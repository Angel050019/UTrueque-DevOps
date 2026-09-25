import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstracción sobre el estado de conectividad del dispositivo, para que
/// la capa de dominio pueda decidir si intenta o no una llamada de red
/// sin depender directamente del paquete connectivity_plus.
abstract class NetworkInfo {
  Future<bool> get estaConectado;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get estaConectado async {
    final List<ConnectivityResult> resultado = await _connectivity.checkConnectivity();
    return !resultado.contains(ConnectivityResult.none);
  }
}
