import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/features/chat/data/models/mensaje_model.dart';
import 'package:utrueque/features/chat/domain/entities/mensaje.dart';
import 'package:utrueque/features/encuentros/data/datasources/encuentros_remote_datasource.dart';
import 'package:utrueque/features/encuentros/data/models/encuentro_model.dart';
import 'package:utrueque/features/encuentros/data/repositories/encuentros_repository_impl.dart';
import 'package:utrueque/features/encuentros/domain/entities/encuentro.dart';
import 'package:utrueque/features/encuentros/domain/entities/punto_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/entities/solicitud_encuentro.dart';

import '../fixtures.dart';

class _MockDataSource extends Mock implements EncuentrosRemoteDataSource {}

Map<String, dynamic> filaEncuentro({String estado = 'propuesto', String? referencia = 'Frente a la puerta'}) =>
    <String, dynamic>{
      'id': 'enc-1',
      'conversacion_id': idConversacion,
      'propuesto_por': idVendedor,
      'punto_id': 'biblioteca',
      'punto_nombre': 'Biblioteca - Entrada Principal',
      'punto_referencia': referencia,
      'fecha_hora': '2026-11-12T19:00:00+00:00',
      'estado': estado,
      'created_at': '2026-11-11T15:00:00+00:00',
      'respondido_en': null,
    };

void main() {
  group('Modelos de HU-08', () {
    test('PuntoEncuentroModel lee una fila del catálogo', () {
      final PuntoEncuentroModel p = PuntoEncuentroModel.fromMap(
        <String, dynamic>{'id': 'cafeteria', 'nombre': 'Cafetería - Área de mesas', 'referencia': null},
      );
      expect(p.id, 'cafeteria');
      expect(p.nombre, 'Cafetería - Área de mesas');
      expect(p.referencia, '');
    });

    test('EncuentroModel lee una fila de encuentros_conversacion', () {
      final EncuentroModel e = EncuentroModel.fromMap(filaEncuentro(estado: 'aceptado'));
      expect(e.id, 'enc-1');
      expect(e.conversacionId, idConversacion);
      expect(e.propuestoPor, idVendedor);
      expect(e.punto.nombre, 'Biblioteca - Entrada Principal');
      expect(e.punto.referencia, 'Frente a la puerta');
      expect(e.fechaHora, jueves13);
      expect(e.estado, EstadoEncuentro.aceptado);
      expect(e.creadoEn, DateTime.utc(2026, 11, 11, 15));
      expect(EncuentroModel.fromMap(filaEncuentro(referencia: null)).punto.referencia, '');
    });

    test('MensajeModel lee el tipo y el encuentro de una tarjeta (HU-08)', () {
      final MensajeModel m = MensajeModel.fromMap(<String, dynamic>{
        'id': 'm9',
        'conversacion_id': idConversacion,
        'autor_id': idVendedor,
        'texto': 'Propuso vernos en Biblioteca - Entrada Principal el jueves 12 de noviembre a las 13:00.',
        'created_at': '2026-11-11T16:00:00+00:00',
        'tipo': 'propuesta',
        'encuentro_id': 'enc-1',
      });
      expect(m.tipo, TipoMensaje.propuesta);
      expect(m.encuentroId, 'enc-1');
      expect(m.esDeEncuentro, isTrue);
    });

    test('MensajeModel sin tipo (HU-07 o migración sin aplicar) es texto normal', () {
      final MensajeModel m = MensajeModel.fromMap(<String, dynamic>{
        'id': 'm1',
        'conversacion_id': idConversacion,
        'autor_id': idVendedor,
        'texto': 'Hola',
        'created_at': '2026-11-11T16:00:00+00:00',
      });
      expect(m.tipo, TipoMensaje.texto);
      expect(m.encuentroId, isNull);
      expect(MensajeModel.columnasSelect, isNot(contains('tipo')));
    });
  });

  group('EncuentrosRepositoryImpl', () {
    late _MockDataSource fuente;
    late EncuentrosRepositoryImpl repositorio;

    setUpAll(() => registerFallbackValue<SolicitudEncuentro>(const CancelacionEncuentro(encuentroId: 'x')));

    setUp(() {
      fuente = _MockDataSource();
      repositorio = EncuentrosRepositoryImpl(fuente);
    });

    test('pide el catálogo una sola vez y lo guarda', () async {
      when(() => fuente.obtenerPuntos()).thenAnswer((_) async => [
            PuntoEncuentroModel(id: biblioteca.id, nombre: biblioteca.nombre, referencia: biblioteca.referencia),
          ]);

      final List<PuntoEncuentro> primera = await repositorio.obtenerPuntos();
      final List<PuntoEncuentro> segunda = await repositorio.obtenerPuntos();

      expect(primera.single.id, biblioteca.id);
      expect(primera.single.nombre, biblioteca.nombre);
      expect(segunda, same(primera));
      verify(() => fuente.obtenerPuntos()).called(1);
    });

    test('un catálogo vacío no se guarda (se vuelve a pedir)', () async {
      when(() => fuente.obtenerPuntos()).thenAnswer((_) async => <PuntoEncuentroModel>[]);
      await repositorio.obtenerPuntos();
      await repositorio.obtenerPuntos();
      verify(() => fuente.obtenerPuntos()).called(2);
    });

    test('los encuentros y las solicitudes pasan a la fuente de datos', () async {
      when(() => fuente.obtenerEncuentros(idConversacion))
          .thenAnswer((_) async => [EncuentroModel.fromMap(filaEncuentro())]);
      when(() => fuente.enviar(any())).thenAnswer((_) async {});

      final List<Encuentro> lista = await repositorio.obtenerEncuentros(idConversacion);
      await repositorio.enviar(const CancelacionEncuentro(encuentroId: 'enc-1'));

      expect(lista.single.id, 'enc-1');
      verify(() => fuente.enviar(const CancelacionEncuentro(encuentroId: 'enc-1'))).called(1);
    });
  });
}
