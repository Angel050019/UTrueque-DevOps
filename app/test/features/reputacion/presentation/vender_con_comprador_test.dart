import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/borrar_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/cambiar_estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_detalle_publicacion.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/gestionar_publicacion_cubit.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/gestionar_publicacion_state.dart';
import 'package:utrueque/features/reputacion/domain/entities/trato.dart';
import 'package:utrueque/features/reputacion/domain/errors/reputacion_failures.dart';
import 'package:utrueque/features/reputacion/domain/usecases/casos_de_uso_reputacion.dart';

import '../fixtures.dart';

class _MockCambiarEstado extends Mock implements CambiarEstadoPublicacion {}

class _MockBorrar extends Mock implements BorrarPublicacion {}

class _MockObtenerDetalle extends Mock implements ObtenerDetallePublicacion {}

/// HU-09, Escenarios 1 y 2: "Marcar como Vendido" en la hoja "Gestionar
/// publicación" pregunta a quién se le vendió.
void main() {
  late MockReputacionRepository repo;
  late MockRed red;
  late _MockObtenerDetalle obtenerDetalle;

  final Publicacion disponible = publicacionDelVendedor();
  final Publicacion reservada = publicacionDelVendedor(estado: const Reservado());

  setUp(() {
    repo = MockReputacionRepository();
    red = MockRed();
    obtenerDetalle = _MockObtenerDetalle();
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  GestionarPublicacionCubit crear(Publicacion publicacion, {bool conReputacion = true}) => GestionarPublicacionCubit(
        publicacion: publicacion,
        cambiarEstado: _MockCambiarEstado(),
        borrarPublicacion: _MockBorrar(),
        obtenerDetalle: obtenerDetalle,
        marcarVendida: conReputacion ? MarcarVendida(repo, red) : null,
      );

  Future<GestionarPublicacionCubit> confirmandoVenta(Publicacion publicacion) async {
    final GestionarPublicacionCubit cubit = crear(publicacion);
    await cubit.elegir(OperacionGestion.marcarVendido);
    expect(cubit.state, GestionConfirmando(publicacion, OperacionGestion.marcarVendido));
    return cubit;
  }

  test('con la reputación activa, "Marcar como Vendido" elige comprador', () {
    expect(crear(disponible).eligeComprador, isTrue);
    expect(crear(disponible, conReputacion: false).eligeComprador, isFalse);
  });

  test('Escenario 1: vende a Beto → Vendida y "Listo. Ya pueden calificarse."', () async {
    when(() => repo.marcarVendida('pub-1', conversacionId: idConversacion)).thenAnswer((_) async => 'venta-1');
    final GestionarPublicacionCubit cubit = await confirmandoVenta(disponible);

    await cubit.venderA(const EleccionVenta.a(idConversacion, nombre: 'Beto Ruiz'));

    final GestionState state = cubit.state;
    expect(state, isA<GestionTerminada>());
    final GestionTerminada terminada = state as GestionTerminada;
    expect(terminada.mensaje, 'Listo. Ya pueden calificarse.');
    expect(terminada.actualizada?.estado, const Vendido());
    expect(terminada.operacion, OperacionGestion.marcarVendido);
    await cubit.close();
  });

  test('Escenario 1: desde Reservada también', () async {
    when(() => repo.marcarVendida('pub-1', conversacionId: idConversacion)).thenAnswer((_) async => 'venta-1');
    final GestionarPublicacionCubit cubit = await confirmandoVenta(reservada);

    await cubit.venderA(const EleccionVenta.a(idConversacion));

    expect((cubit.state as GestionTerminada).actualizada?.estado, const Vendido());
    await cubit.close();
  });

  test('Escenario 2: fuera de UTrueque → mensaje de siempre de HU-06', () async {
    when(() => repo.marcarVendida('pub-1', conversacionId: null)).thenAnswer((_) async => null);
    final GestionarPublicacionCubit cubit = await confirmandoVenta(disponible);

    await cubit.venderA(const EleccionVenta.fueraDeUTrueque());

    expect((cubit.state as GestionTerminada).mensaje, 'Tu publicación se marcó como Vendida.');
    await cubit.close();
  });

  test('Escenario 11: el servidor dice que el comprador no es válido → error y sigue Disponible', () async {
    when(() => repo.marcarVendida('pub-1', conversacionId: 'conv-x')).thenThrow(const CompradorNoValidoFailure());
    final GestionarPublicacionCubit cubit = await confirmandoVenta(disponible);

    await cubit.venderA(const EleccionVenta.a('conv-x'));

    expect(cubit.state, GestionError(disponible, const CompradorNoValidoFailure()));
    await cubit.close();
  });

  test('HU-06, Escenario 9: ya se vendió en otro dispositivo → se recarga', () async {
    final Publicacion yaVendida = publicacionDelVendedor(estado: const Vendido());
    when(() => repo.marcarVendida('pub-1', conversacionId: idConversacion))
        .thenThrow(const AccionNoPermitidaFailure());
    when(() => obtenerDetalle('pub-1')).thenAnswer((_) async => yaVendida);
    final GestionarPublicacionCubit cubit = await confirmandoVenta(disponible);

    await cubit.venderA(const EleccionVenta.a(idConversacion));

    expect(cubit.state, GestionError(yaVendida, const AccionNoPermitidaFailure()));
    await cubit.close();
  });

  test('Escenario 13: sin conexión → error y no se llama al servidor', () async {
    when(() => red.estaConectado).thenAnswer((_) async => false);
    final GestionarPublicacionCubit cubit = await confirmandoVenta(disponible);

    await cubit.venderA(const EleccionVenta.a(idConversacion));

    expect((cubit.state as GestionError).mensaje, 'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.');
    verifyNever(() => repo.marcarVendida(any(), conversacionId: any(named: 'conversacionId')));
    await cubit.close();
  });

  test('Escenario 14: error inesperado → mensaje genérico', () async {
    when(() => repo.marcarVendida('pub-1', conversacionId: idConversacion)).thenThrow(Exception('interno'));
    final GestionarPublicacionCubit cubit = await confirmandoVenta(disponible);

    await cubit.venderA(const EleccionVenta.a(idConversacion));

    expect((cubit.state as GestionError).failure, const GestionarPublicacionFailure());
    await cubit.close();
  });

  test('venderA no hace nada si no se está confirmando la venta', () async {
    final GestionarPublicacionCubit cubit = crear(disponible);

    await cubit.venderA(const EleccionVenta.a(idConversacion));

    expect(cubit.state, GestionLista(disponible));
    verifyNever(() => repo.marcarVendida(any(), conversacionId: any(named: 'conversacionId')));
    await cubit.close();
  });

  test('sin la reputación, venderA vende como en HU-06', () async {
    final _MockCambiarEstado cambiar = _MockCambiarEstado();
    final Publicacion vendida = publicacionDelVendedor(estado: const Vendido());
    when(() => cambiar(disponible, AccionEstado.marcarVendido)).thenAnswer((_) async => vendida);
    final GestionarPublicacionCubit cubit = GestionarPublicacionCubit(
      publicacion: disponible,
      cambiarEstado: cambiar,
      borrarPublicacion: _MockBorrar(),
    );
    await cubit.elegir(OperacionGestion.marcarVendido);

    await cubit.venderA(const EleccionVenta.fueraDeUTrueque());

    expect(cubit.state, GestionTerminada(disponible, OperacionGestion.marcarVendido, actualizada: vendida));
    await cubit.close();
  });
}
