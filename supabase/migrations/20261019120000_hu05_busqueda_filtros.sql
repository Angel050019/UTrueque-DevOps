-- =====================================================================
-- UTrueque · Sprint 5 · HU-05 Búsqueda y filtros (issue #5)
-- Migración: búsqueda por palabras (sin importar mayúsculas ni acentos)
-- y filtros por categoría, división y carrera sobre el Feed paginado.
--
-- Cómo aplicarla: Supabase → SQL Editor → pegar TODO el archivo → Run.
-- Es idempotente: se puede volver a correr sin romper nada.
-- Requiere las migraciones de HU-02, HU-03, el catálogo de la UTSJR y
-- HU-04. No cambia tablas, datos ni reglas de seguridad existentes.
--
-- Compatibilidad: la función feed_publicaciones de HU-04 NO se toca,
-- así que los APK que ya están instalados (Sprints 3 y 4) siguen
-- funcionando. La app del Sprint 5 usa la función nueva
-- buscar_publicaciones. feed_publicaciones se podrá quitar cuando nadie
-- use una versión vieja (propuesta: Sprint 7).
--
-- Cómo la usa la app:
--   POST /rest/v1/rpc/buscar_publicaciones
--   {"p_texto": "calculadora hp",     -- opcional (máx. 100 caracteres)
--    "p_categoria_id": 2,             -- opcional
--    "p_division_id": 11,             -- opcional (división del dueño)
--    "p_carrera_id": 102,             -- opcional (carrera del dueño)
--    "p_antes_de": "<fecha>",         -- opcional: cursor de la página
--    "p_antes_id": "<uuid>",          -- opcional: cursor de la página
--    "p_limite": 20}
--   Sin filtros regresa exactamente lo mismo que el Feed de HU-04.
--   Regresa las mismas columnas que la vista publicaciones_detalle.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Extensión unaccent (quitar acentos: "científica" = "cientifica").
--    En Supabase las extensiones viven en el esquema "extensions".
-- ---------------------------------------------------------------------
create schema if not exists extensions;
create extension if not exists unaccent with schema extensions;

-- ---------------------------------------------------------------------
-- 2. Configuración de búsqueda "es_utrueque"
--    Separa el texto en palabras, las pasa a minúsculas y les quita los
--    acentos ("Científica" → "cientifica"). No recorta las palabras a su
--    raíz: con la raíz del español, "calculadora" y "cálculo" quedan
--    iguales ("calcul") y al buscar calculadoras saldrían libros de
--    cálculo. Se crea solo si no existe; el ALTER deja la misma
--    configuración aunque se corra varias veces.
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_ts_config
    where cfgname = 'es_utrueque' and cfgnamespace = 'public'::regnamespace
  ) then
    create text search configuration public.es_utrueque (copy = pg_catalog.simple);
  end if;
end
$$;

alter text search configuration public.es_utrueque
  alter mapping for asciiword, asciihword, hword_asciipart, word, hword, hword_part
  with extensions.unaccent, pg_catalog.simple;

-- ---------------------------------------------------------------------
-- 3. Índices
--    · Texto: índice GIN sobre título + descripción (solo Disponibles y
--      Reservadas, que son las que se buscan).
--    · Categoría: filtrar por categoría manteniendo el orden del Feed
--      (fecha, id) sin recorrer toda la tabla.
--    · Carrera y división del dueño: para filtrar por el perfil.
-- ---------------------------------------------------------------------
create index if not exists publicaciones_busqueda_idx
  on public.publicaciones
  using gin (to_tsvector('public.es_utrueque'::regconfig, titulo || ' ' || descripcion))
  where estado in ('disponible', 'reservado');

create index if not exists publicaciones_categoria_cursor_idx
  on public.publicaciones (categoria_id, created_at desc, id desc)
  where estado in ('disponible', 'reservado');

create index if not exists usuarios_carrera_idx  on public.usuarios (carrera_id);
create index if not exists usuarios_division_idx on public.usuarios (division_id);

-- ---------------------------------------------------------------------
-- 4. Función public.consulta_busqueda(texto) → tsquery
--    Convierte lo que escribe el estudiante en una consulta segura:
--    · Se queda con los primeros 100 caracteres y máximo 8 palabras
--      (SEGURIDAD: disponibilidad, nadie manda un texto gigante).
--    · Quita signos (& | ! : * ( ) ' ¿ ¡ …) para que el texto nunca se
--      interprete como operadores (SEGURIDAD: validación de entrada).
--    · Ignora palabras vacías del español ("de", "la", "para"…).
--    · Quita la "s" final de palabras de 4 letras o más, para que
--      "calculadoras" encuentre "calculadora" y al revés.
--    · Cada palabra busca "lo que empiece así" (calcu → calculadora) y
--      deben aparecer TODAS, en cualquier orden.
--    · Regresa null si no quedó ninguna palabra (= sin filtro de texto).
-- ---------------------------------------------------------------------
create or replace function public.consulta_busqueda(p_texto text)
returns tsquery
language sql
stable
set search_path = ''
as $$
  select case
    when count(*) = 0 then null
    else to_tsquery('public.es_utrueque'::regconfig, string_agg(w.palabra || ':*', ' & '))
  end
  from (
    select case
             when char_length(palabra) >= 4 and right(palabra, 1) = 's'
               then left(palabra, -1)
             else palabra
           end as palabra
    from regexp_split_to_table(
      translate(
        lower(left(coalesce(p_texto, ''), 100)),
        '!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~¿¡«»“”‘’…',
        repeat(' ', 41)
      ),
      '\s+'
    ) as palabra
    where palabra <> ''
      -- Palabra vacía del español: el diccionario la regresa sin raíz.
      and ts_lexize('pg_catalog.spanish_stem'::regdictionary, palabra) <> '{}'::text[]
    limit 8
  ) w;
$$;

comment on function public.consulta_busqueda(text) is
  'HU-05: convierte el texto del buscador en una consulta segura (prefijos, todas las palabras).';

revoke all on function public.consulta_busqueda(text) from public, anon;
grant execute on function public.consulta_busqueda(text) to authenticated;

-- ---------------------------------------------------------------------
-- 5. Función public.buscar_publicaciones (Feed con búsqueda y filtros)
--    · Mismas reglas que el Feed de HU-04: solo Disponibles y
--      Reservadas, de la más nueva a la más vieja, paginación por
--      cursor (created_at, id) y máximo 50 por página.
--    · Filtros opcionales que se combinan (deben cumplirse todos):
--      texto, categoría, división y carrera del dueño.
--    · security invoker: corre con los permisos de quien la llama, así
--      que el RLS se sigue aplicando (mediación completa).
-- ---------------------------------------------------------------------
drop function if exists public.buscar_publicaciones(text, integer, integer, integer, timestamptz, uuid, integer);

create function public.buscar_publicaciones(
  p_texto         text        default null,
  p_categoria_id  integer     default null,
  p_division_id   integer     default null,
  p_carrera_id    integer     default null,
  p_antes_de      timestamptz default null,
  p_antes_id      uuid        default null,
  p_limite        integer     default 20
)
returns setof public.publicaciones_detalle
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  -- La consulta de texto se arma una sola vez (null = sin texto).
  v_consulta tsquery := public.consulta_busqueda(p_texto);
  v_limite   integer := least(greatest(coalesce(p_limite, 20), 1), 50);
  v_antes_id uuid    := coalesce(p_antes_id, 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid);
begin
  -- Solo signos o palabras vacías ("de", "la"): sin filtro de texto.
  if v_consulta is not null and numnode(v_consulta) = 0 then
    v_consulta := null;
  end if;

  if v_consulta is null then
    -- Sin texto: igual que el Feed de HU-04, más los filtros.
    return query
      select v.*
      from public.publicaciones_detalle v
      where v.estado in ('disponible', 'reservado')
        and (p_categoria_id is null or v.categoria_id      = p_categoria_id)
        and (p_division_id  is null or v.dueno_division_id = p_division_id)
        and (p_carrera_id   is null or v.dueno_carrera_id  = p_carrera_id)
        and (p_antes_de is null or (v.created_at, v.id) < (p_antes_de, v_antes_id))
      order by v.created_at desc, v.id desc
      limit v_limite;
  else
    -- Con texto: primero se buscan las coincidencias con el índice
    -- publicaciones_busqueda_idx y luego se ordenan y paginan. Así una
    -- búsqueda sin resultados no recorre toda la tabla.
    return query
      with coincidencias as materialized (
        select p.id
        from public.publicaciones p
        where p.estado in ('disponible', 'reservado')
          and to_tsvector('public.es_utrueque'::regconfig, p.titulo || ' ' || p.descripcion)
              @@ v_consulta
      )
      select v.*
      from public.publicaciones_detalle v
      where v.id in (select c.id from coincidencias c)
        and v.estado in ('disponible', 'reservado')
        and (p_categoria_id is null or v.categoria_id      = p_categoria_id)
        and (p_division_id  is null or v.dueno_division_id = p_division_id)
        and (p_carrera_id   is null or v.dueno_carrera_id  = p_carrera_id)
        and (p_antes_de is null or (v.created_at, v.id) < (p_antes_de, v_antes_id))
      order by v.created_at desc, v.id desc
      limit v_limite;
  end if;
end
$$;

comment on function public.buscar_publicaciones(text, integer, integer, integer, timestamptz, uuid, integer) is
  'HU-05: Feed con búsqueda por palabras y filtros por categoría, división y carrera. Cursor (created_at, id). Máximo 50.';

-- SEGURIDAD: mínimo privilegio. Solo estudiantes con sesión.
revoke all on function public.buscar_publicaciones(text, integer, integer, integer, timestamptz, uuid, integer) from public, anon;
grant execute on function public.buscar_publicaciones(text, integer, integer, integer, timestamptz, uuid, integer) to authenticated;

-- Pide a la API (PostgREST) que vuelva a leer el esquema para que la
-- función nueva quede disponible de inmediato.
notify pgrst, 'reload schema';

commit;
