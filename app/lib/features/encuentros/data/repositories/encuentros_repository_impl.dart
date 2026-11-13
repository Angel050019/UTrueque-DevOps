import '../../domain/entities/encuentro.dart';
import '../../domain/entities/punto_encuentro.dart';
import '../../domain/entities/solicitud_encuentro.dart';
import '../../domain/repositories/encuentros_repository.dart';
import '../datasources/encuentros_remote_datasource.dart';

/// Implementación de los puntos de encuentro con Supabase (HU-08).
///
/// El catálogo casi nunca cambia: se pide una vez y se guarda mientras la
/// app está abierta. Si la petición falla, se vuelve a intentar la próxima
/// vez.
class EncuentrosRepositoryImpl implements EncuentrosRepository {
  EncuentrosRepositoryImpl(this._remoteDataSource);

  final EncuentrosRemoteDataSource _remoteDataSource;
  List<PuntoEncuentro>? _catalogo;

  @override
  Future<List<PuntoEncuentro>> obtenerPuntos() async {
    final List<PuntoEncuentro>? guardado = _catalogo;
    if (guardado != null && guardado.isNotEmpty) return guardado;
    final List<PuntoEncuentro> puntos = List.unmodifiable(await _remoteDataSource.obtenerPuntos());
    _catalogo = puntos;
    return puntos;
  }

  @override
  Future<List<Encuentro>> obtenerEncuentros(String conversacionId) =>
      _remoteDataSource.obtenerEncuentros(conversacionId);

  @override
  Future<void> enviar(SolicitudEncuentro solicitud) => _remoteDataSource.enviar(solicitud);
}
