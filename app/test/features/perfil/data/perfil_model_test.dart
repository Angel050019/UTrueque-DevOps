import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/perfil/data/models/division_model.dart';
import 'package:utrueque/features/perfil/data/models/perfil_model.dart';
import 'package:utrueque/features/perfil/domain/entities/carrera.dart';

void main() {
  group('PerfilModel.fromMap', () {
    test('lee la fila de usuarios con división y carrera embebidas', () {
      final perfil = PerfilModel.fromMap(const {
        'id': 'u1',
        'nombre_mostrar': 'Ana López',
        'division_id': 1,
        'carrera_id': 2,
        'foto_url': 'https://x/u1/avatar.jpg',
        'perfil_completo': true,
        'division_info': {'nombre': 'TI'},
        'carrera_info': {'nombre': 'Redes'},
      });

      expect(perfil.nombreMostrar, 'Ana López');
      expect(perfil.divisionId, 1);
      expect(perfil.divisionNombre, 'TI');
      expect(perfil.carreraId, 2);
      expect(perfil.carreraNombre, 'Redes');
      expect(perfil.tieneFoto, isTrue);
      expect(perfil.perfilCompleto, isTrue);
    });

    test('tolera un perfil vacío recién creado', () {
      final perfil = PerfilModel.fromMap(const {
        'id': 'u1',
        'nombre_mostrar': null,
        'division_id': null,
        'carrera_id': null,
        'foto_url': null,
        'perfil_completo': false,
        'division_info': null,
        'carrera_info': null,
      });

      expect(perfil.perfilCompleto, isFalse);
      expect(perfil.tieneFoto, isFalse);
      expect(perfil.divisionNombre, isNull);
    });
  });

  test('DivisionModel.fromMap descarta carreras inactivas y las ordena', () {
    final division = DivisionModel.fromMap(const {
      'id': 1,
      'nombre': 'TI',
      'orden': 1,
      'carreras': [
        {'id': 2, 'division_id': 1, 'nombre': 'Redes', 'activo': true, 'orden': 2},
        {'id': 9, 'division_id': 1, 'nombre': 'Vieja', 'activo': false, 'orden': 0},
        {'id': 1, 'division_id': 1, 'nombre': 'Software', 'activo': true, 'orden': 1},
      ],
    });

    expect(division.carreras, const [
      Carrera(id: 1, divisionId: 1, nombre: 'Software'),
      Carrera(id: 2, divisionId: 1, nombre: 'Redes'),
    ]);
  });
}
