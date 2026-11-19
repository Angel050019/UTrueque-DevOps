import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/reputacion/data/models/modelos_reputacion.dart';
import 'package:utrueque/features/reputacion/domain/entities/trato.dart';

import '../fixtures.dart';

void main() {
  group('ResumenReputacionModel', () {
    test('lee los conteos aunque lleguen como texto o decimales', () {
      final ResumenReputacionModel m = ResumenReputacionModel.fromMap(
        <String, dynamic>{'usuario_id': idVendedor, 'total': 4, 'una': 0, 'dos': '1', 'tres': 1.0, 'cuatro': null, 'cinco': 2},
        usuarioId: 'otro',
      );

      expect(m.usuarioId, idVendedor);
      expect([m.una, m.dos, m.tres, m.cuatro, m.cinco], [0, 1, 1, 0, 2]);
      expect(m.total, 4);
    });

    test('si falta el usuario usa el que se pidió', () {
      expect(ResumenReputacionModel.fromMap(const <String, dynamic>{}, usuarioId: idVendedor).usuarioId, idVendedor);
    });
  });

  test('CompradorPosibleModel', () {
    final CompradorPosibleModel m = CompradorPosibleModel.fromMap(<String, dynamic>{
      'conversacion_id': idConversacion,
      'comprador_id': idComprador,
      'comprador_nombre': 'Beto Ruiz',
      'comprador_foto_url': 'https://avatars/beto.jpg',
      'ultimo_mensaje_en': '2026-11-18T16:00:00+00:00',
    });

    expect(m.conversacionId, idConversacion);
    expect(m.nombre, 'Beto Ruiz');
    expect(m.fotoUrl, 'https://avatars/beto.jpg');
    expect(m.ultimoMensajeEn, DateTime.utc(2026, 11, 18, 16));

    final CompradorPosibleModel sinNombre =
        CompradorPosibleModel.fromMap(<String, dynamic>{'conversacion_id': 'c', 'comprador_id': 'x'});
    expect(sinNombre.nombre, 'Estudiante de la UTSJR');
    expect(sinNombre.ultimoMensajeEn, isNull);
  });

  group('TratoPorCalificarModel', () {
    Map<String, dynamic> fila({Object? venceEn = '2026-12-02T16:00:00+00:00'}) => <String, dynamic>{
          'venta_id': 'venta-1',
          'conversacion_id': idConversacion,
          'publicacion_id': 'pub-1',
          'publicacion_titulo': 'Calculadora Casio fx-991',
          'publicacion_foto': '$idVendedor/1_0.jpg',
          'soy_vendedor': false,
          'otro_id': idVendedor,
          'otro_nombre': 'Ana López',
          'otro_foto_url': null,
          'vendida_en': '2026-11-18T16:00:00+00:00',
          'vence_en': venceEn,
        };

    test('convierte la ruta de la portada en URL', () {
      final TratoPorCalificar t = TratoPorCalificarModel.fromMap(fila(), urlFoto: (r) => 'https://fotos/$r');

      expect(t.ventaId, 'venta-1');
      expect(t.conversacionId, idConversacion);
      expect(t.publicacionFotoUrl, 'https://fotos/$idVendedor/1_0.jpg');
      expect(t.soyVendedor, isFalse);
      expect(t.otroNombre, 'Ana López');
      expect(t.vendidaEn, DateTime.utc(2026, 11, 18, 16));
      expect(t.venceEn, DateTime.utc(2026, 12, 2, 16));
    });

    test('sin fecha de vencimiento la calcula (14 días) y sin convertidor deja la ruta', () {
      final TratoPorCalificar t = TratoPorCalificarModel.fromMap(fila(venceEn: null));

      expect(t.venceEn, DateTime.utc(2026, 12, 2, 16));
      expect(t.publicacionFotoUrl, '$idVendedor/1_0.jpg');
    });
  });

  test('CalificacionRecibidaModel', () {
    final CalificacionRecibida c = CalificacionRecibidaModel.fromMap(<String, dynamic>{
      'id': 'c1',
      'estrellas': 5,
      'comentario': 'Muy puntual.',
      'created_at': '2026-11-19T17:00:00+00:00',
      'autor_id': idComprador,
      'autor_nombre': 'Beto Ruiz',
      'autor_foto_url': null,
      'publicacion_titulo': 'Calculadora Casio fx-991',
      'como_vendedor': true,
    });

    // El modelo es otro tipo: se comparan sus datos.
    expect(c.props, recibida('c1').props);
  });
}
