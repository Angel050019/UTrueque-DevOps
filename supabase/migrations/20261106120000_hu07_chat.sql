-- =====================================================================
-- UTrueque · Sprint 7 · HU-07 Chat directo (issue #2)
-- Migración: conversaciones entre el interesado y el vendedor de una
-- publicación, mensajes en tiempo real (Supabase Realtime) y mensajes sin
-- leer.
--
-- Cómo aplicarla: Supabase → SQL Editor → pegar TODO el archivo → Run.
-- Es idempotente: se puede volver a correr sin romper nada.
-- Requiere las migraciones de HU-02 a HU-06 y la de caracteres permitidos.
-- No cambia las tablas ni las funciones que ya existen.
--
-- Reglas (las mismas que aplica la app):
--   · Una conversación por publicación y por interesado.
--   · Solo se INICIA si la publicación está Disponible, no es tuya y tu
--     perfil está completo. Si ya existe, se abre aunque esté Reservada.
--   · Solo los dos participantes ven la conversación y sus mensajes.
--   · Se puede escribir mientras la publicación exista y no esté Vendida.
--     Vendida o borrada: la conversación queda solo para leer.
--   · Mensaje de 1 a 500 caracteres, con la misma lista de caracteres
--     permitidos que la descripción (sin emojis ni < > { } ; ' " …).
--   · Máximo 20 mensajes por minuto por estudiante (contra el spam).
--   · Nadie puede editar ni borrar mensajes.
--
-- Cómo la usa la app:
--   · "Contactar al vendedor":
--       POST /rest/v1/rpc/iniciar_conversacion   {"p_publicacion": "<uuid>"}
--   · Bandeja de mensajes:
--       POST /rest/v1/rpc/mis_conversaciones     {}
--   · Mensajes de una conversación (los más nuevos primero, de 30 en 30):
--       POST /rest/v1/rpc/mensajes_conversacion  {"p_conversacion": "<uuid>"}
--   · Enviar:
--       POST /rest/v1/mensajes   {"conversacion_id": "<uuid>", "texto": "…"}
--   · Marcar como leída:
--       POST /rest/v1/rpc/marcar_conversacion_leida {"p_conversacion": "<uuid>"}
--   · Globo de no leídos:
--       POST /rest/v1/rpc/total_no_leidos        {}
--   · Tiempo real (patrón Observer): la app se suscribe a los INSERT de la
--     tabla mensajes por WebSocket. Realtime respeta las reglas RLS: cada
--     estudiante solo recibe los mensajes de sus conversaciones.
--
-- Cada rechazo llega con una pista (hint) fija para que la app muestre el
-- mensaje correcto, sin detalles internos:
--   publicacion_propia | publicacion_no_disponible | perfil_incompleto |
--   publicacion_no_encontrada | conversacion_cerrada | mensaje_caracteres |
--   demasiados_mensajes
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Tabla conversaciones
--    Si se borra la publicación, la conversación se conserva (solo para
--    leer) con publicacion_id vacío. Si se borra una cuenta, se borran sus
--    conversaciones.
-- ---------------------------------------------------------------------
create table if not exists public.conversaciones (
  id                  uuid primary key default gen_random_uuid(),
  publicacion_id      uuid references public.publicaciones (id) on delete set null,
  comprador_id        uuid not null references public.usuarios (id) on delete cascade,
  vendedor_id         uuid not null references public.usuarios (id) on delete cascade,
  created_at          timestamptz not null default now(),
  ultimo_mensaje_en   timestamptz,
  leido_comprador_en  timestamptz,
  leido_vendedor_en   timestamptz,
  constraint conversaciones_participantes_chk check (comprador_id <> vendedor_id)
);

comment on table public.conversaciones is
  'HU-07: chat entre el interesado (comprador) y el dueño (vendedor) de una publicación.';

create unique index if not exists conversaciones_publicacion_comprador_uq
  on public.conversaciones (publicacion_id, comprador_id);
create index if not exists conversaciones_comprador_idx
  on public.conversaciones (comprador_id, ultimo_mensaje_en desc);
create index if not exists conversaciones_vendedor_idx
  on public.conversaciones (vendedor_id, ultimo_mensaje_en desc);

-- ---------------------------------------------------------------------
-- 2. Tabla mensajes
-- ---------------------------------------------------------------------
create table if not exists public.mensajes (
  id               uuid primary key default gen_random_uuid(),
  conversacion_id  uuid not null references public.conversaciones (id) on delete cascade,
  autor_id         uuid not null default auth.uid() references public.usuarios (id) on delete cascade,
  texto            text not null,
  created_at       timestamptz not null default now(),
  constraint mensajes_texto_chk check (char_length(btrim(texto)) between 1 and 500)
);

comment on table public.mensajes is 'HU-07: mensajes de una conversación. No se editan ni se borran.';

create index if not exists mensajes_conversacion_cursor_idx
  on public.mensajes (conversacion_id, created_at desc, id desc);
create index if not exists mensajes_autor_fecha_idx
  on public.mensajes (autor_id, created_at desc);

-- ---------------------------------------------------------------------
-- 3. SEGURIDAD: RLS
--    Solo los participantes leen. Las conversaciones se crean únicamente
--    con iniciar_conversacion (que revisa las reglas). Los mensajes se
--    envían a nombre propio y solo en conversaciones propias.
-- ---------------------------------------------------------------------
alter table public.conversaciones enable row level security;
alter table public.mensajes enable row level security;

revoke all on public.conversaciones from anon;
revoke all on public.mensajes from anon;
revoke insert, update, delete on public.conversaciones from authenticated;
revoke update, delete on public.mensajes from authenticated;
grant select on public.conversaciones to authenticated;
grant select, insert on public.mensajes to authenticated;

drop policy if exists "Conversaciones: leen sus participantes" on public.conversaciones;
create policy "Conversaciones: leen sus participantes"
  on public.conversaciones for select to authenticated
  using ((select auth.uid()) in (comprador_id, vendedor_id));

drop policy if exists "Mensajes: leen los participantes" on public.mensajes;
create policy "Mensajes: leen los participantes"
  on public.mensajes for select to authenticated
  using (exists (
    select 1 from public.conversaciones c
    where c.id = mensajes.conversacion_id
      and (select auth.uid()) in (c.comprador_id, c.vendedor_id)
  ));

drop policy if exists "Mensajes: envían los participantes a nombre propio" on public.mensajes;
create policy "Mensajes: envían los participantes a nombre propio"
  on public.mensajes for insert to authenticated
  with check (
    autor_id = (select auth.uid())
    and exists (
      select 1 from public.conversaciones c
      where c.id = mensajes.conversacion_id
        and (select auth.uid()) in (c.comprador_id, c.vendedor_id)
    )
  );

-- ---------------------------------------------------------------------
-- 4. SEGURIDAD: reglas al enviar un mensaje (antes de guardar)
-- ---------------------------------------------------------------------
create or replace function public.mensajes_antes_de_guardar()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_estado text;
  v_existe boolean;
begin
  new.created_at := now();

  -- Si la conversación no es del autor, no se encuentra (RLS) y la regla
  -- de RLS rechaza el mensaje después.
  select true, p.estado
    into v_existe, v_estado
    from public.conversaciones c
    left join public.publicaciones p on p.id = c.publicacion_id
   where c.id = new.conversacion_id;
  if v_existe is null then
    return new;
  end if;

  if v_estado is null or v_estado = 'vendido' then
    raise exception 'La conversación ya no acepta mensajes'
      using errcode = 'check_violation', hint = 'conversacion_cerrada';
  end if;

  if new.texto !~ '^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,()/#+:%°$¿?¡!\n-]*$' then
    raise exception 'El mensaje tiene caracteres no permitidos'
      using errcode = 'check_violation', hint = 'mensaje_caracteres';
  end if;

  if (select count(*) from public.mensajes m
       where m.autor_id = new.autor_id
         and m.created_at > now() - interval '1 minute') >= 20 then
    raise exception 'Demasiados mensajes en poco tiempo'
      using errcode = 'check_violation', hint = 'demasiados_mensajes';
  end if;

  return new;
end;
$$;

drop trigger if exists mensajes_antes_de_guardar on public.mensajes;
create trigger mensajes_antes_de_guardar
  before insert on public.mensajes
  for each row execute function public.mensajes_antes_de_guardar();

-- Después de guardar: la conversación sube al inicio de la bandeja.
-- security definer porque los estudiantes no pueden modificar
-- conversaciones directamente; solo cambia la fecha del último mensaje.
create or replace function public.mensajes_despues_de_guardar()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversaciones
     set ultimo_mensaje_en = new.created_at
   where id = new.conversacion_id;
  return new;
end;
$$;

drop trigger if exists mensajes_despues_de_guardar on public.mensajes;
create trigger mensajes_despues_de_guardar
  after insert on public.mensajes
  for each row execute function public.mensajes_despues_de_guardar();

revoke all on function public.mensajes_despues_de_guardar() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 5. Función iniciar_conversacion: "Contactar al vendedor"
--    Devuelve el id de la conversación (la crea si no existe).
--    security definer: es la única forma de crear conversaciones, y revisa
--    todas las reglas con el estudiante de la sesión (auth.uid()).
-- ---------------------------------------------------------------------
create or replace function public.iniciar_conversacion(p_publicacion uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid       uuid := auth.uid();
  v_dueno     uuid;
  v_estado    text;
  v_id        uuid;
begin
  if v_uid is null then
    raise exception 'Sin sesión' using errcode = 'insufficient_privilege';
  end if;

  select usuario_id, estado into v_dueno, v_estado
    from public.publicaciones where id = p_publicacion;
  if v_dueno is null then
    raise exception 'La publicación no existe'
      using errcode = 'no_data_found', hint = 'publicacion_no_encontrada';
  end if;

  if v_dueno = v_uid then
    raise exception 'No puedes contactarte a ti mismo'
      using errcode = 'check_violation', hint = 'publicacion_propia';
  end if;

  -- Si ya existe, se abre (aunque ahora esté Reservada o Vendida).
  select id into v_id from public.conversaciones
   where publicacion_id = p_publicacion and comprador_id = v_uid;
  if v_id is not null then
    return v_id;
  end if;

  if v_estado <> 'disponible' then
    raise exception 'La publicación ya no acepta nuevos contactos'
      using errcode = 'check_violation', hint = 'publicacion_no_disponible';
  end if;

  if not coalesce((select perfil_completo from public.usuarios where id = v_uid), false) then
    raise exception 'Completa tu perfil para contactar'
      using errcode = 'check_violation', hint = 'perfil_incompleto';
  end if;

  insert into public.conversaciones (publicacion_id, comprador_id, vendedor_id)
  values (p_publicacion, v_uid, v_dueno)
  on conflict (publicacion_id, comprador_id) do nothing
  returning id into v_id;

  if v_id is null then  -- se creó al mismo tiempo en otro dispositivo
    select id into v_id from public.conversaciones
     where publicacion_id = p_publicacion and comprador_id = v_uid;
  end if;
  return v_id;
end;
$$;

revoke all on function public.iniciar_conversacion(uuid) from public, anon;
grant execute on function public.iniciar_conversacion(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 6. Función mis_conversaciones: la bandeja de mensajes
--    security invoker: RLS deja ver solo las conversaciones propias.
--    Las más recientes primero; máximo 100.
-- ---------------------------------------------------------------------
drop function if exists public.mis_conversaciones(integer);

create function public.mis_conversaciones(p_limite integer default 50)
returns table (
  id                    uuid,
  publicacion_id        uuid,
  publicacion_titulo    text,
  publicacion_foto      text,
  publicacion_estado    text,
  soy_vendedor          boolean,
  otro_id               uuid,
  otro_nombre           text,
  otro_foto_url         text,
  ultimo_texto          text,
  ultimo_autor_id       uuid,
  ultimo_mensaje_en     timestamptz,
  no_leidos             integer,
  created_at            timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    c.id,
    c.publicacion_id,
    p.titulo,
    p.fotos[1],
    p.estado,
    c.vendedor_id = (select auth.uid()),
    o.id,
    o.nombre_mostrar,
    o.foto_url,
    u.texto,
    u.autor_id,
    c.ultimo_mensaje_en,
    (select count(*)::integer from public.mensajes m
      where m.conversacion_id = c.id
        and m.autor_id <> (select auth.uid())
        and m.created_at > coalesce(
              case when c.vendedor_id = (select auth.uid())
                   then c.leido_vendedor_en else c.leido_comprador_en end,
              '-infinity'::timestamptz)),
    c.created_at
  from public.conversaciones c
  left join public.publicaciones p on p.id = c.publicacion_id
  join public.usuarios o
    on o.id = case when c.vendedor_id = (select auth.uid()) then c.comprador_id else c.vendedor_id end
  left join lateral (
    select m.texto, m.autor_id from public.mensajes m
     where m.conversacion_id = c.id
     order by m.created_at desc, m.id desc
     limit 1
  ) u on true
  order by coalesce(c.ultimo_mensaje_en, c.created_at) desc, c.id desc
  limit least(greatest(coalesce(p_limite, 50), 1), 100);
$$;

revoke all on function public.mis_conversaciones(integer) from public, anon;
grant execute on function public.mis_conversaciones(integer) to authenticated;

-- ---------------------------------------------------------------------
-- 7. Función mensajes_conversacion: mensajes por páginas
--    Los más nuevos primero (la app los voltea). Cursor (created_at, id).
-- ---------------------------------------------------------------------
drop function if exists public.mensajes_conversacion(uuid, timestamptz, uuid, integer);

create function public.mensajes_conversacion(
  p_conversacion uuid,
  p_antes_de     timestamptz default null,
  p_antes_id     uuid        default null,
  p_limite       integer     default 30
)
returns setof public.mensajes
language sql
stable
security invoker
set search_path = ''
as $$
  select m.*
  from public.mensajes m
  where m.conversacion_id = p_conversacion
    and (
      p_antes_de is null
      or (m.created_at, m.id) <
         (p_antes_de, coalesce(p_antes_id, 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid))
    )
  order by m.created_at desc, m.id desc
  limit least(greatest(coalesce(p_limite, 30), 1), 100);
$$;

revoke all on function public.mensajes_conversacion(uuid, timestamptz, uuid, integer) from public, anon;
grant execute on function public.mensajes_conversacion(uuid, timestamptz, uuid, integer) to authenticated;

-- ---------------------------------------------------------------------
-- 8. Función marcar_conversacion_leida
--    Solo cambia la marca de lectura del estudiante que la llama.
-- ---------------------------------------------------------------------
create or replace function public.marcar_conversacion_leida(p_conversacion uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.conversaciones c
     set leido_comprador_en = case when c.comprador_id = auth.uid() then now() else c.leido_comprador_en end,
         leido_vendedor_en  = case when c.vendedor_id  = auth.uid() then now() else c.leido_vendedor_en end
   where c.id = p_conversacion
     and auth.uid() in (c.comprador_id, c.vendedor_id);
$$;

revoke all on function public.marcar_conversacion_leida(uuid) from public, anon;
grant execute on function public.marcar_conversacion_leida(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 9. Función total_no_leidos: el globo del ícono de mensajes
--    Cuántas conversaciones tienen mensajes sin leer.
-- ---------------------------------------------------------------------
create or replace function public.total_no_leidos()
returns integer
language sql
stable
security invoker
set search_path = ''
as $$
  select count(*)::integer
  from public.conversaciones c
  where exists (
    select 1 from public.mensajes m
     where m.conversacion_id = c.id
       and m.autor_id <> (select auth.uid())
       and m.created_at > coalesce(
             case when c.vendedor_id = (select auth.uid())
                  then c.leido_vendedor_en else c.leido_comprador_en end,
             '-infinity'::timestamptz)
  );
$$;

revoke all on function public.total_no_leidos() from public, anon;
grant execute on function public.total_no_leidos() to authenticated;

-- ---------------------------------------------------------------------
-- 10. Tiempo real: mensajes en la publicación de Supabase Realtime
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
        where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'mensajes'
     ) then
    alter publication supabase_realtime add table public.mensajes;
  end if;
end;
$$;

notify pgrst, 'reload schema';

commit;

-- ---------------------------------------------------------------------
-- Comprobación después de aplicarla: debe regresar 4 filas con "sí".
-- ---------------------------------------------------------------------
-- select 'tabla conversaciones' as que, case when to_regclass('public.conversaciones') is not null then 'sí' else 'NO' end as existe
-- union all select 'tabla mensajes', case when to_regclass('public.mensajes') is not null then 'sí' else 'NO' end
-- union all select 'función iniciar_conversacion', case when to_regprocedure('public.iniciar_conversacion(uuid)') is not null then 'sí' else 'NO' end
-- union all select 'mensajes en tiempo real', case when exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'mensajes') then 'sí' else 'NO' end;
