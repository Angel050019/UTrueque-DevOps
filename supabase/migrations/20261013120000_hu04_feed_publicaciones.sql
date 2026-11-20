-- =====================================================================
-- UTrueque · Sprint 4 · HU-04 Feed de publicaciones
-- Migración: vista con los datos que muestran el Feed y el Detalle,
-- función para pedir el Feed por páginas (cursor) e índice para que
-- esa consulta sea rápida aunque haya miles de publicaciones.
--
-- Cómo aplicarla: Supabase → SQL Editor → pegar TODO el archivo → Run.
-- Es idempotente: se puede volver a correr sin romper nada.
-- Requiere las migraciones de HU-02, HU-03 y el catálogo de la UTSJR.
-- No cambia tablas, datos ni reglas de seguridad existentes.
--
-- Cómo la usa la app:
--   · Feed (primera página):
--       POST /rest/v1/rpc/feed_publicaciones   {"p_limite": 20}
--   · Feed (siguiente página): manda la fecha y el id de la ÚLTIMA
--     publicación que ya tiene:
--       POST /rest/v1/rpc/feed_publicaciones
--       {"p_antes_de": "2026-10-13T18:00:00.123456+00:00",
--        "p_antes_id": "<uuid>", "p_limite": 20}
--   · Detalle:
--       GET /rest/v1/publicaciones_detalle?id=eq.<uuid>
--     Si regresa vacío, la publicación se borró.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Índice para el Feed paginado
--    Ordena por fecha (más nueva primero) y por id para desempatar
--    publicaciones creadas en el mismo instante. Es "parcial": solo
--    guarda Disponibles y Reservadas, que son las que se ven en el Feed.
--    (El índice publicaciones_feed_idx de HU-03 se conserva.)
-- ---------------------------------------------------------------------
create index if not exists publicaciones_feed_cursor_idx
  on public.publicaciones (created_at desc, id desc)
  where estado in ('disponible', 'reservado');

-- ---------------------------------------------------------------------
-- 2. Se quitan la función y la vista anteriores (si existen) para
--    poder volver a crearlas aunque cambien sus columnas.
--    Primero la función, porque depende de la vista.
-- ---------------------------------------------------------------------
drop function if exists public.feed_publicaciones(timestamptz, uuid, integer);
drop view if exists public.publicaciones_detalle;

-- ---------------------------------------------------------------------
-- 3. Vista public.publicaciones_detalle
--    Une la publicación con su categoría y con el perfil público del
--    dueño (nombre, foto, división y carrera). La usan el Feed y el
--    Detalle, y en el Sprint 5 servirá para filtrar por división y
--    carrera (por eso trae también los ids).
--
--    SEGURIDAD: security_invoker = on → la vista se consulta con los
--    permisos de quien la pide, así que se siguen aplicando las reglas
--    RLS de publicaciones, usuarios y catálogos (mediación completa).
--    Sin esto, una vista en Postgres saltaría el RLS.
--    SEGURIDAD: minimización. Del dueño solo salen datos que ya son
--    públicos en su perfil; nunca el correo.
-- ---------------------------------------------------------------------
create view public.publicaciones_detalle
with (security_invoker = on)
as
select
  p.id,
  p.usuario_id,
  p.titulo,
  p.descripcion,
  p.categoria_id,
  c.nombre          as categoria_nombre,
  p.modalidad,
  p.precio,
  p.estado,
  p.fotos,
  p.created_at,
  p.updated_at,
  u.nombre_mostrar  as dueno_nombre,
  u.foto_url        as dueno_foto_url,
  u.division_id     as dueno_division_id,
  d.nombre          as dueno_division,
  u.carrera_id      as dueno_carrera_id,
  ca.nombre         as dueno_carrera
from public.publicaciones p
join public.categorias c       on c.id  = p.categoria_id
join public.usuarios u         on u.id  = p.usuario_id
left join public.divisiones d  on d.id  = u.division_id
left join public.carreras ca   on ca.id = u.carrera_id;

comment on view public.publicaciones_detalle is
  'HU-04: publicación + categoría + perfil público del dueño. Feed y Detalle.';

-- SEGURIDAD: mínimo privilegio. Solo estudiantes con sesión.
revoke all on public.publicaciones_detalle from public, anon;
grant select on public.publicaciones_detalle to authenticated;

-- ---------------------------------------------------------------------
-- 4. Función public.feed_publicaciones (Feed por páginas)
--    · Solo Disponibles y Reservadas (las Vendidas salen del Feed).
--    · De la más nueva a la más vieja.
--    · Paginación por cursor: en lugar de "salta 40 y dame 20" (que se
--      vuelve lento y repite o se salta publicaciones cuando alguien
--      publica mientras haces scroll), se pide "dame las 20 anteriores
--      a la última que ya tengo".
--    · p_limite se acota entre 1 y 50 (SEGURIDAD: nadie puede pedir la
--      tabla completa de un jalón).
--    · security invoker: corre con los permisos de quien la llama.
-- ---------------------------------------------------------------------
create function public.feed_publicaciones(
  p_antes_de  timestamptz default null,
  p_antes_id  uuid        default null,
  p_limite    integer     default 20
)
returns setof public.publicaciones_detalle
language sql
stable
security invoker
set search_path = ''
as $$
  select v.*
  from public.publicaciones_detalle v
  where v.estado in ('disponible', 'reservado')
    and (
      p_antes_de is null
      -- Si falta el id, se toma el más alto para no perder empates.
      or (v.created_at, v.id) <
         (p_antes_de, coalesce(p_antes_id, 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid))
    )
  order by v.created_at desc, v.id desc
  limit least(greatest(coalesce(p_limite, 20), 1), 50);
$$;

comment on function public.feed_publicaciones(timestamptz, uuid, integer) is
  'HU-04: Feed paginado por cursor (created_at, id). Máximo 50 por página.';

revoke all on function public.feed_publicaciones(timestamptz, uuid, integer) from public, anon;
grant execute on function public.feed_publicaciones(timestamptz, uuid, integer) to authenticated;

-- Pide a la API (PostgREST) que vuelva a leer el esquema para que la vista
-- y la función queden disponibles de inmediato.
notify pgrst, 'reload schema';

commit;
