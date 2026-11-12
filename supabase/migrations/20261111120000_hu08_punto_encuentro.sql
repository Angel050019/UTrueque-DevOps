-- =====================================================================
-- UTrueque · Sprint 8 · HU-08 Punto de encuentro seguro (issue #3)
-- Migración: catálogo de puntos de encuentro oficiales de la UTSJR,
-- propuestas de encuentro dentro del chat (proponer, aceptar, rechazar,
-- cancelar) y tarjetas de encuentro en la conversación.
--
-- Cómo aplicarla: Supabase → SQL Editor → pegar TODO el archivo → Run.
-- Es idempotente: se puede volver a correr sin romper nada.
-- Requiere las migraciones de HU-02 a HU-07 y la de caracteres permitidos.
-- Único cambio a algo que ya existe: la tabla mensajes gana dos columnas
-- (tipo y encuentro_id) con valores por omisión; los mensajes de HU-07 no
-- cambian y la app de HU-07 sigue funcionando igual.
--
-- Reglas (las mismas que aplica la app):
--   · Solo se puede elegir un lugar del catálogo oficial (no hay texto
--     libre). Un lugar fuera del catálogo o desactivado se rechaza.
--   · Cualquiera de los dos participantes propone; el OTRO acepta o
--     rechaza. Nadie acepta su propia propuesta.
--   · Horario: de lunes a viernes, de 7:00 a 20:00 (hora del centro de
--     México), en horas exactas o medias horas, desde 30 minutos después
--     de ahora y hasta 14 días adelante.
--   · Un solo encuentro activo (propuesto o aceptado) por conversación.
--     Para cambiarlo: rechazar o cancelar, y proponer otro.
--   · Cancelar: una propuesta, solo quien la hizo; un encuentro aceptado,
--     cualquiera de los dos.
--   · Igual que los mensajes: la publicación debe existir y no estar
--     Vendida. Cada propuesta o respuesta cuenta para el límite de 20
--     mensajes por minuto.
--
-- Cómo la usa la app:
--   · Catálogo (solo los activos, en orden):
--       GET  /rest/v1/puntos_encuentro?select=id,nombre,referencia&order=orden
--   · Proponer:
--       POST /rest/v1/rpc/proponer_encuentro
--            {"p_conversacion": "<uuid>", "p_punto": "biblioteca",
--             "p_fecha_hora": "2026-11-12T13:00:00-06:00"}
--   · Aceptar o rechazar:
--       POST /rest/v1/rpc/responder_encuentro {"p_encuentro": "<uuid>", "p_acepta": true}
--   · Cancelar:
--       POST /rest/v1/rpc/cancelar_encuentro  {"p_encuentro": "<uuid>"}
--   · Encuentros de una conversación (para dibujar las tarjetas):
--       POST /rest/v1/rpc/encuentros_conversacion {"p_conversacion": "<uuid>"}
--   · Tiempo real (patrón Observer de HU-07): cada propuesta o respuesta
--     crea un mensaje con tipo y encuentro_id, que llega por el mismo
--     WebSocket de la tabla mensajes. Así el otro estudiante ve la tarjeta
--     al instante, sube el globo de no leídos y la conversación sube en la
--     bandeja ("se avisa a los dos"). No hay notificación push (HU-10).
--
-- Cada rechazo llega con una pista (hint) fija, sin detalles internos:
--   punto_no_permitido | horario_no_permitido | encuentro_activo |
--   encuentro_propio | encuentro_no_pendiente | encuentro_no_activo |
--   encuentro_vencido | conversacion_cerrada | demasiados_mensajes
--   (si la conversación o el encuentro no son tuyos: código 42501, sin pista)
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Catálogo de puntos de encuentro oficiales (regla de negocio).
--    El id es un texto corto y fijo para poder volver a correr el archivo.
--    Para quitar un lugar: activo = false (las propuestas viejas se siguen
--    viendo, pero ya no se puede proponer ahí).
--    Los nombres usan solo caracteres permitidos (lista del Sprint 6).
-- ---------------------------------------------------------------------
create table if not exists public.puntos_encuentro (
  id          text primary key,
  nombre      text not null,
  referencia  text not null,
  orden       smallint not null default 0,
  activo      boolean not null default true,
  constraint puntos_encuentro_id_chk check (id ~ '^[a-z0-9-]{2,40}$'),
  constraint puntos_encuentro_nombre_chk check (
    char_length(btrim(nombre)) between 3 and 60
    and nombre ~ '^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,()/#+:%°-]*$')
);

comment on table public.puntos_encuentro is
  'HU-08: lugares oficiales y seguros dentro de la UTSJR donde se puede hacer la entrega.';

-- Lista inicial PROPUESTA por el equipo; la confirman los Product Owners
-- (decisión 2 de la planeación). Si cambia, se edita aquí y se vuelve a correr.
insert into public.puntos_encuentro (id, nombre, referencia, orden) values
  ('biblioteca',  'Biblioteca - Entrada Principal', 'Frente a la puerta principal de la biblioteca', 1),
  ('cafeteria',   'Cafetería - Área de mesas',      'Mesas junto a la barra de la cafetería',        2),
  ('edificio-k',  'Edificio K - Planta baja',       'Vestíbulo de la planta baja del Edificio K',    3),
  ('explanada',   'Explanada principal',            'Centro de la explanada, junto al asta bandera', 4),
  ('acceso',      'Acceso principal - Vigilancia',  'Junto a la caseta de vigilancia de la entrada', 5)
on conflict (id) do update
  set nombre = excluded.nombre, referencia = excluded.referencia, orden = excluded.orden;

alter table public.puntos_encuentro enable row level security;
revoke all on public.puntos_encuentro from anon, authenticated;
grant select on public.puntos_encuentro to authenticated;

drop policy if exists "Puntos de encuentro: leen los estudiantes" on public.puntos_encuentro;
create policy "Puntos de encuentro: leen los estudiantes"
  on public.puntos_encuentro for select to authenticated
  using (true);

-- ---------------------------------------------------------------------
-- 2. Tabla encuentros: cada propuesta dentro de una conversación.
--    Estados: propuesto → aceptado | rechazado | cancelado | vencido;
--             aceptado  → cancelado | concluido (ya pasó la hora).
-- ---------------------------------------------------------------------
create table if not exists public.encuentros (
  id               uuid primary key default gen_random_uuid(),
  conversacion_id  uuid not null references public.conversaciones (id) on delete cascade,
  propuesto_por    uuid not null references public.usuarios (id) on delete cascade,
  punto_id         text not null references public.puntos_encuentro (id),
  fecha_hora       timestamptz not null,
  estado           text not null default 'propuesto',
  created_at       timestamptz not null default now(),
  respondido_por   uuid references public.usuarios (id) on delete set null,
  respondido_en    timestamptz,
  constraint encuentros_estado_chk check (
    estado in ('propuesto', 'aceptado', 'rechazado', 'cancelado', 'vencido', 'concluido'))
);

comment on table public.encuentros is
  'HU-08: propuestas de punto de encuentro dentro de una conversación del chat.';

-- Un solo encuentro activo por conversación.
create unique index if not exists encuentros_un_activo_uq
  on public.encuentros (conversacion_id) where estado in ('propuesto', 'aceptado');
create index if not exists encuentros_conversacion_idx
  on public.encuentros (conversacion_id, created_at desc);

-- SEGURIDAD: solo los participantes leen; nadie escribe directo (solo con
-- las funciones de abajo, que revisan las reglas).
alter table public.encuentros enable row level security;
revoke all on public.encuentros from anon, authenticated;
grant select on public.encuentros to authenticated;

drop policy if exists "Encuentros: leen los participantes" on public.encuentros;
create policy "Encuentros: leen los participantes"
  on public.encuentros for select to authenticated
  using (exists (
    select 1 from public.conversaciones c
    where c.id = encuentros.conversacion_id
      and (select auth.uid()) in (c.comprador_id, c.vendedor_id)
  ));

-- ---------------------------------------------------------------------
-- 3. Mensajes: tipo y encuentro_id (la tarjeta del chat).
--    'texto' es el mensaje normal de HU-07 (valor por omisión).
-- ---------------------------------------------------------------------
alter table public.mensajes
  add column if not exists tipo         text not null default 'texto',
  add column if not exists encuentro_id uuid references public.encuentros (id) on delete cascade;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'mensajes_tipo_chk') then
    alter table public.mensajes
      add constraint mensajes_tipo_chk check (
        (tipo = 'texto' and encuentro_id is null)
        or (tipo in ('propuesta', 'aceptado', 'rechazado', 'cancelado') and encuentro_id is not null));
  end if;
end;
$$;

create index if not exists mensajes_encuentro_idx on public.mensajes (encuentro_id) where encuentro_id is not null;

-- SEGURIDAD: un estudiante no puede fabricar una tarjeta de encuentro con
-- un POST directo a /rest/v1/mensajes. Solo las funciones de HU-08 (que se
-- ejecutan como su dueño, no como "authenticated") pueden crearlas.
create or replace function public.mensajes_tipo_seguro()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (new.tipo <> 'texto' or new.encuentro_id is not null)
     and current_user in ('authenticated', 'anon') then
    raise exception 'Tipo de mensaje no permitido'
      using errcode = 'insufficient_privilege';
  end if;
  return new;
end;
$$;

drop trigger if exists mensajes_tipo_seguro on public.mensajes;
create trigger mensajes_tipo_seguro
  before insert on public.mensajes
  for each row execute function public.mensajes_tipo_seguro();

-- ---------------------------------------------------------------------
-- 4. Funciones de apoyo (internas; la app no las llama)
-- ---------------------------------------------------------------------

-- ¿La fecha y hora cumplen el horario permitido?
create or replace function public.encuentro_horario_valido(p_fecha_hora timestamptz)
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_fecha_hora is not null
     and p_fecha_hora >= now() + interval '30 minutes'
     and p_fecha_hora <= now() + interval '14 days'
     and extract(isodow from (p_fecha_hora at time zone 'America/Mexico_City')) between 1 and 5
     and (p_fecha_hora at time zone 'America/Mexico_City')::time between time '07:00' and time '20:00'
     and extract(minute from (p_fecha_hora at time zone 'America/Mexico_City')) in (0, 30)
     and extract(second from (p_fecha_hora at time zone 'America/Mexico_City')) = 0;
$$;

-- "jueves 12 de noviembre a las 13:00"
create or replace function public.encuentro_fecha_texto(p_fecha_hora timestamptz)
returns text
language sql
stable
set search_path = ''
as $$
  select (array['lunes','martes','miércoles','jueves','viernes','sábado','domingo'])
           [extract(isodow from l)::int]
         || ' ' || extract(day from l)::int || ' de '
         || (array['enero','febrero','marzo','abril','mayo','junio','julio','agosto',
                   'septiembre','octubre','noviembre','diciembre'])[extract(month from l)::int]
         || ' a las ' || to_char(l, 'HH24:MI')
    from (select p_fecha_hora at time zone 'America/Mexico_City' as l) x;
$$;

-- Revisa que el estudiante de la sesión participe en la conversación y que
-- ésta acepte mensajes. Bloquea la conversación para evitar dos propuestas
-- al mismo tiempo.
create or replace function public.encuentro_revisar_conversacion(p_conversacion uuid, p_uid uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_existe boolean;
  v_estado text;
begin
  select true, p.estado into v_existe, v_estado
    from public.conversaciones c
    left join public.publicaciones p on p.id = c.publicacion_id
   where c.id = p_conversacion
     and p_uid in (c.comprador_id, c.vendedor_id)
     for update of c;
  if v_existe is null then
    raise exception 'Sin acceso a la conversación' using errcode = 'insufficient_privilege';
  end if;
  if v_estado is null or v_estado = 'vendido' then
    raise exception 'La conversación ya no acepta mensajes'
      using errcode = 'check_violation', hint = 'conversacion_cerrada';
  end if;

  -- Los encuentros cuya hora ya pasó dejan de estar activos.
  update public.encuentros
     set estado = case estado when 'propuesto' then 'vencido' else 'concluido' end
   where conversacion_id = p_conversacion
     and estado in ('propuesto', 'aceptado')
     and fecha_hora <= now();
end;
$$;

revoke all on function public.encuentro_horario_valido(timestamptz) from public, anon, authenticated;
revoke all on function public.encuentro_fecha_texto(timestamptz) from public, anon, authenticated;
revoke all on function public.encuentro_revisar_conversacion(uuid, uuid) from public, anon, authenticated;
revoke all on function public.mensajes_tipo_seguro() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 5. proponer_encuentro: devuelve el id del encuentro nuevo.
--    security definer: es la única forma de crear encuentros y tarjetas;
--    todo se revisa con el estudiante de la sesión (auth.uid()).
-- ---------------------------------------------------------------------
create or replace function public.proponer_encuentro(
  p_conversacion uuid,
  p_punto        text,
  p_fecha_hora   timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid();
  v_nombre text;
  v_id     uuid;
begin
  if v_uid is null then
    raise exception 'Sin sesión' using errcode = 'insufficient_privilege';
  end if;

  perform public.encuentro_revisar_conversacion(p_conversacion, v_uid);

  -- Escenario 2: solo lugares del catálogo oficial y activos.
  select nombre into v_nombre from public.puntos_encuentro where id = p_punto and activo;
  if v_nombre is null then
    raise exception 'Solo se permiten zonas seguras de la UTSJR'
      using errcode = 'check_violation', hint = 'punto_no_permitido';
  end if;

  if not public.encuentro_horario_valido(p_fecha_hora) then
    raise exception 'Horario no permitido'
      using errcode = 'check_violation', hint = 'horario_no_permitido';
  end if;

  if exists (select 1 from public.encuentros
              where conversacion_id = p_conversacion and estado in ('propuesto', 'aceptado')) then
    raise exception 'Ya hay un encuentro activo'
      using errcode = 'check_violation', hint = 'encuentro_activo';
  end if;

  insert into public.encuentros (conversacion_id, propuesto_por, punto_id, fecha_hora)
  values (p_conversacion, v_uid, p_punto, p_fecha_hora)
  returning id into v_id;

  insert into public.mensajes (conversacion_id, autor_id, texto, tipo, encuentro_id)
  values (p_conversacion, v_uid,
          'Propuso vernos en ' || v_nombre || ' el ' || public.encuentro_fecha_texto(p_fecha_hora) || '.',
          'propuesta', v_id);

  return v_id;
end;
$$;

revoke all on function public.proponer_encuentro(uuid, text, timestamptz) from public, anon;
grant execute on function public.proponer_encuentro(uuid, text, timestamptz) to authenticated;

-- ---------------------------------------------------------------------
-- 6. responder_encuentro: aceptar (p_acepta = true) o rechazar.
--    Escenario 1: al aceptar se crea la tarjeta de confirmación.
-- ---------------------------------------------------------------------
create or replace function public.responder_encuentro(p_encuentro uuid, p_acepta boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid();
  v_e     public.encuentros%rowtype;
  v_nombre text;
begin
  if v_uid is null then
    raise exception 'Sin sesión' using errcode = 'insufficient_privilege';
  end if;

  select e.* into v_e
    from public.encuentros e
    join public.conversaciones c on c.id = e.conversacion_id
   where e.id = p_encuentro
     and v_uid in (c.comprador_id, c.vendedor_id);
  if v_e.id is null then
    raise exception 'Sin acceso al encuentro' using errcode = 'insufficient_privilege';
  end if;

  perform public.encuentro_revisar_conversacion(v_e.conversacion_id, v_uid);

  if v_e.propuesto_por = v_uid then
    raise exception 'No puedes responder tu propia propuesta'
      using errcode = 'check_violation', hint = 'encuentro_propio';
  end if;

  select * into v_e from public.encuentros where id = p_encuentro for update;
  if v_e.estado = 'vencido' then
    raise exception 'La hora propuesta ya pasó'
      using errcode = 'check_violation', hint = 'encuentro_vencido';
  end if;
  if v_e.estado <> 'propuesto' then
    raise exception 'La propuesta ya no está pendiente'
      using errcode = 'check_violation', hint = 'encuentro_no_pendiente';
  end if;

  update public.encuentros
     set estado = case when p_acepta then 'aceptado' else 'rechazado' end,
         respondido_por = v_uid,
         respondido_en = now()
   where id = p_encuentro;

  select nombre into v_nombre from public.puntos_encuentro where id = v_e.punto_id;

  insert into public.mensajes (conversacion_id, autor_id, texto, tipo, encuentro_id)
  values (v_e.conversacion_id, v_uid,
          case when coalesce(p_acepta, false)
               then 'Aceptó el punto de encuentro: ' || v_nombre || ' el '
                    || public.encuentro_fecha_texto(v_e.fecha_hora) || '.'
               else 'Rechazó la propuesta de vernos en ' || v_nombre || '.' end,
          case when coalesce(p_acepta, false) then 'aceptado' else 'rechazado' end,
          p_encuentro);
end;
$$;

revoke all on function public.responder_encuentro(uuid, boolean) from public, anon;
grant execute on function public.responder_encuentro(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------
-- 7. cancelar_encuentro
-- ---------------------------------------------------------------------
create or replace function public.cancelar_encuentro(p_encuentro uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid();
  v_e      public.encuentros%rowtype;
  v_nombre text;
begin
  if v_uid is null then
    raise exception 'Sin sesión' using errcode = 'insufficient_privilege';
  end if;

  select e.* into v_e
    from public.encuentros e
    join public.conversaciones c on c.id = e.conversacion_id
   where e.id = p_encuentro
     and v_uid in (c.comprador_id, c.vendedor_id);
  if v_e.id is null then
    raise exception 'Sin acceso al encuentro' using errcode = 'insufficient_privilege';
  end if;

  perform public.encuentro_revisar_conversacion(v_e.conversacion_id, v_uid);

  select * into v_e from public.encuentros where id = p_encuentro for update;
  if v_e.estado not in ('propuesto', 'aceptado') then
    raise exception 'El encuentro ya no está activo'
      using errcode = 'check_violation', hint = 'encuentro_no_activo';
  end if;
  if v_e.estado = 'propuesto' and v_e.propuesto_por <> v_uid then
    raise exception 'Solo quien propuso puede cancelar; tú puedes rechazarla'
      using errcode = 'check_violation', hint = 'encuentro_propio';
  end if;

  update public.encuentros
     set estado = 'cancelado', respondido_por = v_uid, respondido_en = now()
   where id = p_encuentro;

  select nombre into v_nombre from public.puntos_encuentro where id = v_e.punto_id;

  insert into public.mensajes (conversacion_id, autor_id, texto, tipo, encuentro_id)
  values (v_e.conversacion_id, v_uid,
          'Canceló el encuentro en ' || v_nombre || ' del '
            || public.encuentro_fecha_texto(v_e.fecha_hora) || '.',
          'cancelado', p_encuentro);
end;
$$;

revoke all on function public.cancelar_encuentro(uuid) from public, anon;
grant execute on function public.cancelar_encuentro(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 8. encuentros_conversacion: los encuentros de una conversación, el más
--    reciente primero (máx. 50). security invoker: RLS deja ver solo los
--    de conversaciones propias. Si la hora ya pasó se informa como
--    vencido (propuesta) o concluido (aceptado).
-- ---------------------------------------------------------------------
drop function if exists public.encuentros_conversacion(uuid);

create function public.encuentros_conversacion(p_conversacion uuid)
returns table (
  id                uuid,
  conversacion_id   uuid,
  propuesto_por     uuid,
  punto_id          text,
  punto_nombre      text,
  punto_referencia  text,
  fecha_hora        timestamptz,
  estado            text,
  created_at        timestamptz,
  respondido_en     timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select e.id, e.conversacion_id, e.propuesto_por, e.punto_id, p.nombre, p.referencia, e.fecha_hora,
         case when e.estado = 'propuesto' and e.fecha_hora <= now() then 'vencido'
              when e.estado = 'aceptado'  and e.fecha_hora <= now() then 'concluido'
              else e.estado end,
         e.created_at, e.respondido_en
    from public.encuentros e
    join public.puntos_encuentro p on p.id = e.punto_id
   where e.conversacion_id = p_conversacion
   order by e.created_at desc, e.id desc
   limit 50;
$$;

revoke all on function public.encuentros_conversacion(uuid) from public, anon;
grant execute on function public.encuentros_conversacion(uuid) to authenticated;

notify pgrst, 'reload schema';

commit;

-- ---------------------------------------------------------------------
-- Comprobación después de aplicarla (para José Luis): debe regresar
-- 7 filas, todas con "sí".
-- ---------------------------------------------------------------------
-- select 'catálogo con lugares activos' as que, case when (select count(*) from public.puntos_encuentro where activo) >= 1 then 'sí' else 'NO' end as listo
-- union all select 'tabla encuentros', case when to_regclass('public.encuentros') is not null then 'sí' else 'NO' end
-- union all select 'columna mensajes.tipo', case when exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'mensajes' and column_name = 'tipo') then 'sí' else 'NO' end
-- union all select 'función proponer_encuentro', case when to_regprocedure('public.proponer_encuentro(uuid,text,timestamptz)') is not null then 'sí' else 'NO' end
-- union all select 'función responder_encuentro', case when to_regprocedure('public.responder_encuentro(uuid,boolean)') is not null then 'sí' else 'NO' end
-- union all select 'función cancelar_encuentro', case when to_regprocedure('public.cancelar_encuentro(uuid)') is not null then 'sí' else 'NO' end
-- union all select 'mensajes en tiempo real (HU-07)', case when exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'mensajes') then 'sí' else 'NO' end;
