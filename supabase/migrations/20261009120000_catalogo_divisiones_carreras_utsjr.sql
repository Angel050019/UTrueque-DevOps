-- =====================================================================
-- UTrueque · Sprint 3 · Catálogo de Divisiones y Carreras de la UTSJR
-- Reemplaza el catálogo PROVISIONAL que sembró la migración de HU-02.
--
-- Cómo aplicarla: Supabase → SQL Editor → pegar TODO el archivo → Run.
-- Requiere la migración de HU-02. No depende de la de HU-03.
-- Es idempotente: se puede volver a correr sin romper nada.
--
-- Fuentes (investigación de Jonathan, 09/10/2026):
--   · Informe SEAES de la UTSJR (enero 2024): 5 divisiones y la lista de
--     carreras por nivel.
--   · Cuenta pública 2025 del estado: 12 TSU y 9 ingenierías /
--     licenciaturas en el plantel de San Juan del Río (coincide abajo).
--   · Directorio de cuerpos académicos de la UTSJR: confirma qué áreas
--     están en cada división.
-- ⚠️ El acomodo carrera → división se dedujo por el nombre de cada
--    división. Si Servicios Escolares indica otro, se corrige con una
--    migración nueva; la app no necesita cambios.
--
-- Qué hace:
--   1. Agrega las 5 divisiones y sus 26 carreras (21 de San Juan del Río
--      + 5 de Jalpan) con ids nuevos (divisiones 11-15, carreras 101-126).
--   2. Pasa a los estudiantes que eligieron una carrera provisional que sí
--      existe a su carrera real; a los demás les borra división y carrera
--      para que la app les pida completar su perfil otra vez.
--   3. Desactiva (activo = false) el catálogo provisional. No se borra para
--      que, si alguien vuelve a correr la migración de HU-02, no reaparezca.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Divisiones
-- ---------------------------------------------------------------------
insert into public.divisiones (id, nombre, orden) values
  (11, 'Mecatrónica, Desarrollo de Software e Ingeniería Civil', 1),
  (12, 'Química y Energías Renovables',                          2),
  (13, 'Sistemas Productivos y Mantenimiento Industrial',        3),
  (14, 'Negocios y Mercadotecnia',                               4),
  (15, 'Unidad Académica de Jalpan de Serra',                    5)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- 2. Carreras (primero ingenierías / licenciaturas, después TSU)
-- ---------------------------------------------------------------------
insert into public.carreras (id, division_id, nombre, orden) values
  -- Mecatrónica, Desarrollo de Software e Ingeniería Civil
  (101, 11, 'Ingeniería en Mecatrónica',                                                   1),
  (102, 11, 'Ingeniería en Desarrollo y Gestión de Software',                              2),
  (103, 11, 'Ingeniería Civil',                                                            3),
  (104, 11, 'TSU en Mecatrónica Área Automatización',                                      4),
  (105, 11, 'TSU en Tecnologías de la Información Área Desarrollo de Software Multiplataforma', 5),
  (106, 11, 'TSU en Construcción',                                                         6),

  -- Química y Energías Renovables
  (107, 12, 'Ingeniería Química',                                                          1),
  (108, 12, 'Ingeniería en Química Farmacéutica',                                          2),
  (109, 12, 'Ingeniería en Energías Renovables',                                           3),
  (110, 12, 'TSU en Química Área Industrial',                                              4),
  (111, 12, 'TSU en Química Área Tecnología Farmacéutica',                                 5),
  (112, 12, 'TSU en Energías Renovables Área Energía Solar',                               6),
  (113, 12, 'TSU en Energías Renovables Área Calidad y Ahorro de Energía',                 7),

  -- Sistemas Productivos y Mantenimiento Industrial
  (114, 13, 'Ingeniería en Sistemas Productivos',                                          1),
  (115, 13, 'Ingeniería en Mantenimiento Industrial',                                      2),
  (116, 13, 'TSU en Mantenimiento Área Industrial',                                        3),
  (117, 13, 'TSU en Procesos Industriales Área Manufactura',                               4),
  (118, 13, 'TSU en Procesos Industriales Área Sistemas de Gestión de la Calidad',         5),
  (119, 13, 'TSU en Procesos Industriales Área Plásticos',                                 6),

  -- Negocios y Mercadotecnia
  (120, 14, 'Licenciatura en Innovación de Negocios y Mercadotecnia',                      1),
  (121, 14, 'TSU en Desarrollo de Negocios Área Mercadotecnia',                            2),

  -- Unidad Académica de Jalpan de Serra
  (122, 15, 'Licenciatura en Innovación de Negocios y Mercadotecnia',                      1),
  (123, 15, 'Ingeniería en Desarrollo y Gestión de Software',                              2),
  (124, 15, 'TSU en Desarrollo de Negocios',                                               3),
  (125, 15, 'TSU en Tecnologías de la Información Área Desarrollo de Software Multiplataforma', 4),
  (126, 15, 'TSU Asesor Cooperativo Financiero (DUAL)',                                    5)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- 3. Estudiantes que eligieron del catálogo provisional
--    (va antes de desactivarlo; la llave compuesta exige que la carrera
--    nueva pertenezca a la división nueva, y así es en las tres).
-- ---------------------------------------------------------------------
update public.usuarios u
set division_id = m.division_nueva,
    carrera_id  = m.carrera_nueva
from (values
  -- (carrera provisional, división nueva, carrera nueva)
  (1, 11, 102),  -- Ing. en Desarrollo y Gestión de Software
  (3, 13, 115),  -- Ing. en Mantenimiento Industrial
  (4, 11, 101)   -- Ing. en Mecatrónica
) as m (carrera_provisional, division_nueva, carrera_nueva)
where u.carrera_id = m.carrera_provisional;

-- Las demás carreras provisionales no existen en la UTSJR (Redes,
-- Administración, Contaduría). Al quedar sin división ni carrera, el
-- trigger de HU-02 pone perfil_completo = false y la app les pide
-- completar su perfil en el siguiente inicio de sesión.
update public.usuarios
set division_id = null,
    carrera_id  = null
where division_id between 1 and 3
   or carrera_id  between 1 and 6;

-- ---------------------------------------------------------------------
-- 4. Desactivar el catálogo provisional (la app solo muestra activo = true)
-- ---------------------------------------------------------------------
update public.carreras   set activo = false where id between 1 and 6 and activo;
update public.divisiones set activo = false where id between 1 and 3 and activo;

-- Mueve los contadores de identity para que futuros inserts no choquen.
select setval(pg_get_serial_sequence('public.divisiones', 'id'),
              greatest((select max(id) from public.divisiones), 1));
select setval(pg_get_serial_sequence('public.carreras', 'id'),
              greatest((select max(id) from public.carreras), 1));

commit;
