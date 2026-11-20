import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/aviso_chat.dart';
import '../../domain/usecases/escuchar_chat.dart';
import '../../domain/usecases/obtener_total_no_leidos.dart';

/// El número del globo del ícono de mensajes en el Feed (HU-07,
/// Escenario 8): cuántas conversaciones tienen mensajes sin leer.
///
/// Patrón Observer: cuando llega un mensaje de otro estudiante, se vuelve a
/// pedir el total.
class NoLeidosCubit extends Cubit<int> {
  NoLeidosCubit({
    required ObtenerTotalNoLeidos obtenerTotal,
    required EscucharChat escuchar,
    required String? miId,
  })  : _obtener = obtenerTotal,
        _escuchar = escuchar,
        _miId = miId,
        super(0);

  final ObtenerTotalNoLeidos _obtener;
  final EscucharChat _escuchar;
  final String? _miId;

  StreamSubscription<AvisoChat>? _suscripcion;

  /// Pide el total y se queda escuchando el tiempo real.
  Future<void> iniciar() async {
    _suscripcion ??= _escuchar().listen(_alAviso, onError: (Object _) {});
    await actualizar();
  }

  /// Vuelve a pedir el total (por ejemplo, al regresar de la bandeja). Si no
  /// hay conexión, el globo conserva el número que tenía.
  Future<void> actualizar() async {
    final int? total = await _obtener();
    if (total != null && !isClosed) emit(total);
  }

  void _alAviso(AvisoChat aviso) {
    switch (aviso) {
      case MensajeRecibido(:final mensaje):
        if (!mensaje.esDe(_miId)) unawaited(actualizar());
      case ChatConectado():
        unawaited(actualizar());
    }
  }

  @override
  Future<void> close() async {
    await _suscripcion?.cancel();
    return super.close();
  }
}
