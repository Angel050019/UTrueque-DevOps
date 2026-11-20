import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/encuentros/domain/validators/horario_encuentro.dart';

import '../fixtures.dart';

void main() {
  const HorarioEncuentro horario = HorarioEncuentro();

  /// Un instante con la hora de la universidad.
  DateTime mx(int dia, int hora, [int minuto = 0, int segundo = 0]) =>
      DateTime.utc(2026, 11, dia, hora, minuto, segundo).add(const Duration(hours: 6));

  group('HU-08, Escenario 6: horario permitido', () {
    test('lunes a viernes de 7:00 a 20:00, en horas exactas o medias horas', () {
      expect(horario.esValido(jueves13, ahora: ahora), isTrue);
      expect(horario.esValido(mx(12, 7), ahora: ahora), isTrue);
      expect(horario.esValido(mx(12, 20), ahora: ahora), isTrue);
      expect(horario.esValido(mx(13, 9, 30), ahora: ahora), isTrue);
    });

    test('fuera de horario, en sábado o domingo, o en minutos sueltos no se permite', () {
      expect(horario.esValido(sabado10, ahora: ahora), isFalse);
      expect(horario.esValido(mx(15, 10), ahora: ahora), isFalse); // domingo
      expect(horario.esValido(mx(12, 6, 30), ahora: ahora), isFalse);
      expect(horario.esValido(mx(12, 20, 30), ahora: ahora), isFalse);
      expect(horario.esValido(mx(12, 10, 15), ahora: ahora), isFalse);
      expect(horario.esValido(mx(12, 10, 0, 30), ahora: ahora), isFalse);
      expect(horario.esValido(null, ahora: ahora), isFalse);
    });

    test('desde 30 minutos después de ahora y hasta 14 días adelante', () {
      expect(horario.esValido(ahora, ahora: ahora), isFalse);
      expect(horario.esValido(mx(11, 10, 30), ahora: ahora), isTrue);
      expect(horario.esValido(mx(11, 9), ahora: ahora), isFalse);
      expect(horario.esValido(mx(25, 10), ahora: ahora), isTrue); // justo 14 días
      expect(horario.esValido(mx(25, 10, 30), ahora: ahora), isFalse);
      expect(horario.esValido(mx(26, 10), ahora: ahora), isFalse);
    });

    test('usa la hora de la universidad aunque el instante venga con otra zona horaria', () {
      // 13:00 en la universidad son las 19:00 UTC; el mismo instante en hora local del celular.
      expect(horario.esValido(jueves13.toLocal(), ahora: ahora), isTrue);
      expect(HorarioEncuentro.enMexico(jueves13), DateTime.utc(2026, 11, 12, 13));
      expect(HorarioEncuentro.instante(DateTime.utc(2026, 11, 12), 13, 0), jueves13);
    });
  });

  group('Días y horarios que ofrece la hoja', () {
    test('solo días de lunes a viernes con algún horario, de hoy hasta 14 días', () {
      final List<DateTime> dias = horario.diasDisponibles(ahora: ahora);
      expect(dias.map((d) => d.day), [11, 12, 13, 16, 17, 18, 19, 20, 23, 24, 25]);
      expect(dias.every((d) => d.weekday <= DateTime.friday), isTrue);
    });

    test('hoy empieza 30 minutos después de ahora; un día completo va de 7:00 a 20:00', () {
      final List<DateTime> hoy = horario.horasDisponibles(DateTime.utc(2026, 11, 11), ahora: ahora);
      expect(HorarioEncuentro.formatearHora(hoy.first), '10:30');
      expect(HorarioEncuentro.formatearHora(hoy.last), '20:00');
      expect(hoy, hasLength(20));

      final List<DateTime> jueves = horario.horasDisponibles(DateTime.utc(2026, 11, 12), ahora: ahora);
      expect(HorarioEncuentro.formatearHora(jueves.first), '07:00');
      expect(jueves, hasLength(27));
      expect(jueves, contains(jueves13));
    });

    test('ya de noche, el día de hoy no aparece', () {
      final DateTime noche = mx(11, 19, 45);
      expect(horario.horasDisponibles(DateTime.utc(2026, 11, 11), ahora: noche), isEmpty);
      expect(horario.diasDisponibles(ahora: noche).first.day, 12);
    });

    test('un sábado no tiene horarios', () {
      expect(horario.horasDisponibles(DateTime.utc(2026, 11, 14), ahora: ahora), isEmpty);
    });
  });

  group('Textos', () {
    test('fecha y hora en español con la hora de la universidad', () {
      expect(HorarioEncuentro.formatear(jueves13), 'jueves 12 de noviembre, 13:00');
      expect(HorarioEncuentro.formatearDia(DateTime.utc(2026, 11, 11)), 'miércoles 11 de noviembre');
      expect(HorarioEncuentro.formatearDiaCorto(DateTime.utc(2026, 11, 11)), 'mié 11');
      expect(HorarioEncuentro.formatearHora(mx(12, 7, 30)), '07:30');
    });
  });
}
