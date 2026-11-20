-- =====================================================================
-- UTrueque · Sprint 6 · HU-06 Gestión de "Mis publicaciones" (issue #1)
-- Migración: lista paginada de MIS publicaciones (activas y finalizadas),
-- reglas para editar y borrar según el estado, e índice para esa lista.
--
-- Cómo aplicarla: Supabase → SQL Editor → pegar TODO el archivo → Run.
-- Es idempotente: se puede volver a correr sin romper nada.
-- Requiere las migraciones de HU-02, HU-03, catálogo UTSJR, HU-04 y HU-05.
-- OJO: reemplaza la función del trigger de HU-03. Si alguna vez se vuelve
-- a correr la migración de HU-03, hay que correr esta otra vez después.
--
-- NO cambia tablas, columnas, datos ni las funciones del Feed
-- (feed_publicaciones y buscar_publicaciones siguen igual, así que los APK
-- de los Sprints 3, 4 y 5 siguen funcionando).
--
-- Lo que ya existía y se reutiliza (HU-03):
--   · RLS: solo el dueño puede editar y borrar su publicación.
--   · Trigger: cambios de estado del patrón State
--       disponible → reservado | vendido
--       reservado  → disponible | vendido
--       vendido    → (ninguno: es el estado final)
--   · Storage: cada quien solo borra fotos de su propia carpeta.
--
-- Lo nuevo de HU-06:
--   1. Índice para "Mis publicaciones".
--   2. Regla: solo una publicación Disponible se puede EDITAR
--      (título, descripción, categoría, modalidad, precio y fotos).
--      Reservada → primero se libera; Vendida → solo se ve (historial).
--   3. Regla: solo una publicación Disponible se puede BORRAR.
--   4. Función mis_publicaciones (activas o finalizadas, por páginas).
--
-- Cómo la usa la app:
--   · Mis publicaciones (pestaña Activas, primera página):
--       POST /rest/v1/rpc/mis_publicaciones  {"p_limite": 20}
--   · Pestaña Finalizadas:
--       POST /rest/v1/rpc/mis_publicaciones  {"p_finalizadas": true, "p_limite": 20}
--   · Siguiente página: igual que el Feed, con p_antes_de y p_antes_id.
--   · Cambiar estado:
--       PATCH /rest/v1/publicaciones?id=eq.<uuid>   {"estado": "reservado"}
--   · Editar:
--       PATCH /rest/v1/publicaciones?id=eq.<uuid>   {"titulo": ..., ...}
--   · Borrar (y luego la app borra sus fotos de Storage):
--       DELETE /rest/v1/publicaciones?id=eq.<uuid>
--
-- Cada rechazo de una regla llega como error 23514 con una "pista" (hint)
-- fija para que la app muestre el mensaje correcto, sin detalles internos:
--   transicion_no_permitida | publicacion_no_editable | publicacion_no_borrable
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Índice para "Mis publicaciones"
--    Mis publicaciones de la más nueva a la más vieja, con el id para
--    desempatar (mismo cursor que el Feed).
-- ---------------------------------------------------------------------
create index if not exists publicaciones_usuario_cursor_idx
  on public.publicaciones (usuario_id, created_at desc, id desc);

-- ---------------------------------------------------------------------
-- 2. SEGURIDAD: trigger antes de guardar (se reemplaza el de HU-03).
--    Conserva TODAS las reglas de HU-03 y agrega:
--    · Una publicación que no está Disponible no puede cambiar su
--      contenido (título, descripción, categoría, modalidad, precio,
--      fotos). Sí puede cambiar de estado si la transición es válida.
--    · Cada rechazo lleva una pista (hint) fija para la app.
-- ---------------------------------------------------------------------
create or replace function public.publicaciones_antes_de_guardar()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.estado     := 'disponible';
    new.created_at := now();
  else
    new.usuario_id := old.usuario_id;
    new.created_at := old.created_at;

    -- Patrón State: solo las transiciones permitidas (HU-03).
    if new.estado is distinct from old.estado and not (
         (old.estado = 'disponible' and new.estado in ('reservado', 'vendido'))
      or (old.estado = 'reservado'  and new.estado in ('disponible', 'vendido'))
    ) then
      raise exception 'Cambio de estado no permitido: % → %', old.estado, new.estado
        using errcode = 'check_violation', hint = 'transicion_no_permitida';
    end if;

    -- HU-06: solo una publicación Disponible se edita.
    if old.estado <> 'disponible' and (
         new.titulo       is distinct from old.titulo
      or new.descripcion  is distinct from old.descripcion
      or new.categoria_id is distinct from old.categoria_id
      or new.modalidad    is distinct from old.modalidad
      or new.precio       is distinct from old.precio
      or new.fotos        is distinct from old.fotos
    ) then
      raise exception 'Solo se puede editar una publicación Disponible'
        using errcode = 'check_violation', hint = 'publicacion_no_editable';
    end if;
  end if;

  if exists (
    select 1 from unnest(new.fotos) as f(ruta)
    where f.ruta not like new.usuario_id::text || '/%'
  ) then
    raise exception 'Las fotos deben estar en la carpeta del dueño de la publicación'
      using errcode = 'check_violation';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

-- El trigger de HU-03 ya apunta a esta función; se vuelve a crear por si
-- alguien lo borró, así el archivo deja todo en el estado correcto.
drop trigger if exists publicaciones_antes_de_guardar on public.publicaciones;
create trigger publicaciones_antes_de_guardar
  before insert or update on public.publicaciones
  for each row execute function public.publicaciones_antes_de_guardar();

-- ---------------------------------------------------------------------
-- 3. SEGURIDAD: trigger antes de borrar.
--    Un estudiante solo puede borrar una publicación Disponible:
--    · Reservada: hay un trato en curso → primero se libera.
--    · Vendida: queda en su historial (la reputación de HU-09 la usará).
--    No aplica cuando:
--    · El borrado viene en cascada (se eliminó la cuenta del estudiante).
--    · Lo hace el equipo desde el panel (rol distinto de "authenticated").
-- ---------------------------------------------------------------------
create or replace function public.publicaciones_antes_de_borrar()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user = 'authenticated'
     and pg_trigger_depth() = 1
     and old.estado <> 'disponible' then
    raise exception 'Solo se puede borrar una publicación Disponible'
      using errcode = 'check_violation', hint = 'publicacion_no_borrable';
  end if;
  return old;
end;
$$;

drop trigger if exists publicaciones_antes_de_borrar on public.publicaciones;
create trigger publicaciones_antes_de_borrar
  before delete on public.publicaciones
  for each row execute function public.publicaciones_antes_de_borrar();

-- ---------------------------------------------------------------------
-- 4. Función public.mis_publicaciones
--    · Solo las publicaciones del estudiante que la llama: el dueño sale
--      de su sesión (auth.uid()), NO de un parámetro. Así nadie puede
--      pedir la lista completa de otro (incluidas sus Vendidas).
--    · p_finalizadas = false → Activas (Disponibles y Reservadas).
--      p_finalizadas = true  → Finalizadas (Vendidas), el historial.
--    · De la más nueva a la más vieja, por cursor (created_at, id),
--      máximo 50 por página. Igual que el Feed.
--    · security invoker: corre con los permisos de quien la llama.
-- ---------------------------------------------------------------------
drop function if exists public.mis_publicaciones(boolean, timestamptz, uuid, integer);

create function public.mis_publicaciones(
  p_finalizadas boolean     default false,
  p_antes_de    timestamptz default null,
  p_antes_id    uuid        default null,
  p_limite      integer     default 20
)
returns setof public.publicaciones_detalle
language sql
stable
security invoker
set search_path = ''
as $$
  select v.*
  from public.publicaciones_detalle v
  where v.usuario_id = (select auth.uid())
    and (
      (coalesce(p_finalizadas, false)     and v.estado = 'vendido')
      or (not coalesce(p_finalizadas, false) and v.estado in ('disponible', 'reservado'))
    )
    and (
      p_antes_de is null
      or (v.created_at, v.id) <
         (p_antes_de, coalesce(p_antes_id, 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid))
    )
  order by v.created_at desc, v.id desc
  limit least(greatest(coalesce(p_limite, 20), 1), 50);
$$;

comment on function public.mis_publicaciones(boolean, timestamptz, uuid, integer) is
  'HU-06: publicaciones del estudiante con sesión. Activas o Finalizadas (Vendidas). Cursor (created_at, id). Máximo 50.';

-- SEGURIDAD: mínimo privilegio. Solo estudiantes con sesión.
revoke all on function public.mis_publicaciones(boolean, timestamptz, uuid, integer) from public, anon;
grant execute on function public.mis_publicaciones(boolean, timestamptz, uuid, integer) to authenticated;

notify pgrst, 'reload schema';

commit;

-- ---------------------------------------------------------------------
-- Comprobación rápida después de aplicarla (acción de mejora del
-- Sprint 5): debe regresar 3 filas con "sí".
-- ---------------------------------------------------------------------
-- select 'función mis_publicaciones' as que,
--        case when to_regprocedure('public.mis_publicaciones(boolean,timestamptz,uuid,integer)') is not null then 'sí' else 'NO' end as existe
-- union all
-- select 'trigger antes de borrar',
--        case when exists (select 1 from pg_trigger where tgname = 'publicaciones_antes_de_borrar') then 'sí' else 'NO' end
-- union all
-- select 'índice mis publicaciones',
--        case when to_regclass('public.publicaciones_usuario_cursor_idx') is not null then 'sí' else 'NO' end;
