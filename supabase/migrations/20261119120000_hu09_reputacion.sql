-- =====================================================================
-- UTrueque · Sprint 9 · HU-09 Reputación de 1 a 5 estrellas (issue #38)
-- Migración: al marcar una publicación como Vendida, el vendedor elige con
-- quién hizo el trato (entre sus conversaciones de esa publicación). Con
-- eso, el comprador y el vendedor se califican una sola vez, de 1 a 5
-- estrellas y con un comentario opcional, dentro de los 14 días
-- siguientes. La reputación de cada estudiante se ve en Mi perfil, en el
-- Detalle de la publicación y en el encabezado del chat.
--
-- Cómo aplicarla: Supabase → SQL Editor → pegar TODO el archivo → Run.
-- Es idempotente: se puede volver a correr sin romper nada.
-- Requiere las migraciones de HU-02 a HU-08 y la de caracteres permitidos.
-- NO cambia tablas, columnas ni funciones que ya existen: solo agrega.
-- El "Marcar como Vendido" de HU-06 (PATCH directo) sigue funcionando
-- para los APK viejos, pero esas ventas no tienen comprador y no se
-- califican.
--
-- Reglas (las mismas que aplica la app):
--   · Solo el dueño marca su publicación como Vendida, desde Disponible o
--     Reservada (patrón State de HU-06; Vendido es final).
--   · El comprador se elige entre las conversaciones de ESA publicación
--     en las que el interesado escribió al menos un mensaje. También se
--     puede vender "fuera de UTrueque": entonces nadie califica.
--   · Solo califican los dos del trato; cada uno califica al OTRO
--     (nadie se califica a sí mismo) y una sola vez por trato.
--   · De 1 a 5 estrellas (enteras). Comentario opcional de hasta 200
--     caracteres, con la lista de caracteres permitidos del Sprint 6.
--   · Hay 14 días después de la venta para calificar.
--   · Las calificaciones no se editan ni se borran.
--   · Cada quien ve el detalle (estrellas y comentario) solo de las que
--     dio y de las que recibió. De los demás solo se ve el resumen
--     (cuántas de cada estrella); el promedio lo calcula la app (patrón
--     Strategy: promedio ajustado con menos de 5 calificaciones).
--
-- Cómo la usa la app:
--   · Hoja "¿A quién se lo vendiste?":
--       POST /rest/v1/rpc/compradores_posibles {"p_publicacion": "<uuid>"}
--   · Marcar como Vendido (con o sin comprador):
--       POST /rest/v1/rpc/marcar_vendida {"p_publicacion": "<uuid>", "p_conversacion": "<uuid>|null"}
--   · Tratos que me faltan por calificar (Mi perfil y chat):
--       POST /rest/v1/rpc/tratos_por_calificar {}
--   · Calificar:
--       POST /rest/v1/rpc/calificar {"p_venta": "<uuid>", "p_estrellas": 5, "p_comentario": "…"}
--   · Resumen de reputación de un estudiante (Perfil, Detalle, chat):
--       POST /rest/v1/rpc/reputacion_usuario {"p_usuario": "<uuid>"}
--   · Calificaciones que recibí (Mi perfil, de 20 en 20):
--       POST /rest/v1/rpc/calificaciones_recibidas {"p_limite": 20}
--
-- Cada rechazo llega con una pista (hint) fija, sin detalles internos:
--   publicacion_no_encontrada | transicion_no_permitida | comprador_no_valido |
--   calificacion_duplicada | plazo_vencido | estrellas_invalidas |
--   comentario_caracteres | comentario_largo
--   (si la publicación o el trato no son tuyos: código 42501, sin pista)
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Tabla ventas: el trato entre el vendedor y el comprador elegido.
--    Una venta por publicación. Si alguien borra su cuenta, se borran los
--    tratos en los que participó y sus calificaciones (en cascada).
-- ---------------------------------------------------------------------
create table if not exists public.ventas (
  id               uuid primary key default gen_random_uuid(),
  publicacion_id   uuid not null references public.publicaciones (id) on delete cascade,
  conversacion_id  uuid references public.conversaciones (id) on delete set null,
  vendedor_id      uuid not null references public.usuarios (id) on delete cascade,
  comprador_id     uuid not null references public.usuarios (id) on delete cascade,
  vendida_en       timestamptz not null default now(),
  constraint ventas_participantes_chk check (vendedor_id <> comprador_id)
);

comment on table public.ventas is
  'HU-09: trato concluido (publicación Vendida) entre el vendedor y el comprador que eligió.';

create unique index if not exists ventas_publicacion_uq on public.ventas (publicacion_id);
create index if not exists ventas_vendedor_idx  on public.ventas (vendedor_id, vendida_en desc);
create index if not exists ventas_comprador_idx on public.ventas (comprador_id, vendida_en desc);

-- ---------------------------------------------------------------------
-- 2. Tabla calificaciones
-- ---------------------------------------------------------------------
create table if not exists public.calificaciones (
  id             uuid primary key default gen_random_uuid(),
  venta_id       uuid not null references public.ventas (id) on delete cascade,
  autor_id       uuid not null references public.usuarios (id) on delete cascade,
  calificado_id  uuid not null references public.usuarios (id) on delete cascade,
  estrellas      smallint not null,
  comentario     text,
  created_at     timestamptz not null default now(),
  constraint calificaciones_estrellas_chk check (estrellas between 1 and 5),
  constraint calificaciones_no_propia_chk check (autor_id <> calificado_id),
  constraint calificaciones_comentario_chk check (
    comentario is null
    or (char_length(btrim(comentario)) between 1 and 200
        and comentario ~ '^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,()/#+:%°$¿?¡!\n-]*$'))
);

comment on table public.calificaciones is
  'HU-09: calificación de 1 a 5 estrellas que un participante de un trato le da al otro. No se edita ni se borra.';

-- Una calificación por persona y por trato.
create unique index if not exists calificaciones_venta_autor_uq
  on public.calificaciones (venta_id, autor_id);
create index if not exists calificaciones_calificado_idx
  on public.calificaciones (calificado_id, created_at desc, id desc);

-- ---------------------------------------------------------------------
-- 3. SEGURIDAD: RLS
--    Ventas: solo las ven sus dos participantes.
--    Calificaciones: solo las ven quien la dio y quien la recibió.
--    Nadie escribe directo: solo con marcar_vendida y calificar.
-- ---------------------------------------------------------------------
alter table public.ventas enable row level security;
alter table public.calificaciones enable row level security;

revoke all on public.ventas from anon, authenticated;
revoke all on public.calificaciones from anon, authenticated;
grant select on public.ventas to authenticated;
grant select on public.calificaciones to authenticated;

drop policy if exists "Ventas: leen sus participantes" on public.ventas;
create policy "Ventas: leen sus participantes"
  on public.ventas for select to authenticated
  using ((select auth.uid()) in (vendedor_id, comprador_id));

drop policy if exists "Calificaciones: leen el autor y el calificado" on public.calificaciones;
create policy "Calificaciones: leen el autor y el calificado"
  on public.calificaciones for select to authenticated
  using ((select auth.uid()) in (autor_id, calificado_id));

-- ---------------------------------------------------------------------
-- 4. compradores_posibles: para la hoja "¿A quién se lo vendiste?".
--    Las conversaciones de MI publicación en las que el interesado me
--    escribió al menos un mensaje. security invoker: RLS deja ver solo mis
--    conversaciones; además se filtra por vendedor = yo.
-- ---------------------------------------------------------------------
drop function if exists public.compradores_posibles(uuid);

create function public.compradores_posibles(p_publicacion uuid)
returns table (
  conversacion_id    uuid,
  comprador_id       uuid,
  comprador_nombre   text,
  comprador_foto_url text,
  ultimo_mensaje_en  timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select c.id, c.comprador_id, u.nombre_mostrar, u.foto_url, c.ultimo_mensaje_en
    from public.conversaciones c
    join public.usuarios u on u.id = c.comprador_id
   where c.publicacion_id = p_publicacion
     and c.vendedor_id = (select auth.uid())
     and exists (select 1 from public.mensajes m
                  where m.conversacion_id = c.id and m.autor_id = c.comprador_id)
   order by c.ultimo_mensaje_en desc nulls last, c.id
   limit 50;
$$;

revoke all on function public.compradores_posibles(uuid) from public, anon;
grant execute on function public.compradores_posibles(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 5. marcar_vendida: cambia la publicación a Vendida y, si se eligió una
--    conversación, registra el trato. Devuelve el id de la venta (o null
--    si se vendió fuera de UTrueque).
--    security definer: es la única forma de crear ventas; todo se revisa
--    con el estudiante de la sesión (auth.uid()). El cambio de estado lo
--    sigue revisando el trigger del patrón State (HU-03/HU-06).
-- ---------------------------------------------------------------------
create or replace function public.marcar_vendida(
  p_publicacion  uuid,
  p_conversacion uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid       uuid := auth.uid();
  v_dueno     uuid;
  v_estado    text;
  v_comprador uuid;
  v_id        uuid;
begin
  if v_uid is null then
    raise exception 'Sin sesión' using errcode = 'insufficient_privilege';
  end if;

  select usuario_id, estado into v_dueno, v_estado
    from public.publicaciones where id = p_publicacion
     for update;
  if v_dueno is null then
    raise exception 'La publicación no existe'
      using errcode = 'no_data_found', hint = 'publicacion_no_encontrada';
  end if;
  if v_dueno <> v_uid then
    raise exception 'Sin acceso a la publicación' using errcode = 'insufficient_privilege';
  end if;
  if v_estado not in ('disponible', 'reservado') then
    raise exception 'Cambio de estado no permitido: % → vendido', v_estado
      using errcode = 'check_violation', hint = 'transicion_no_permitida';
  end if;

  if p_conversacion is not null then
    select c.comprador_id into v_comprador
      from public.conversaciones c
     where c.id = p_conversacion
       and c.publicacion_id = p_publicacion
       and c.vendedor_id = v_uid
       and exists (select 1 from public.mensajes m
                    where m.conversacion_id = c.id and m.autor_id = c.comprador_id);
    if v_comprador is null then
      raise exception 'Elige a alguien que te escribió por esta publicación'
        using errcode = 'check_violation', hint = 'comprador_no_valido';
    end if;
  end if;

  update public.publicaciones set estado = 'vendido' where id = p_publicacion;

  if v_comprador is not null then
    insert into public.ventas (publicacion_id, conversacion_id, vendedor_id, comprador_id)
    values (p_publicacion, p_conversacion, v_uid, v_comprador)
    returning id into v_id;
  end if;

  return v_id;
end;
$$;

revoke all on function public.marcar_vendida(uuid, uuid) from public, anon;
grant execute on function public.marcar_vendida(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 6. calificar: califica al otro participante del trato.
--    security definer: es la única forma de crear calificaciones. Quién
--    califica sale de la sesión y a quién se califica sale de la venta
--    (no de un parámetro), así nadie se califica a sí mismo ni a un
--    tercero.
-- ---------------------------------------------------------------------
create or replace function public.calificar(
  p_venta      uuid,
  p_estrellas  integer,
  p_comentario text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid        uuid := auth.uid();
  v_v          public.ventas%rowtype;
  v_otro       uuid;
  v_comentario text := nullif(btrim(coalesce(p_comentario, '')), '');
  v_id         uuid;
begin
  if v_uid is null then
    raise exception 'Sin sesión' using errcode = 'insufficient_privilege';
  end if;

  select * into v_v from public.ventas
   where id = p_venta and v_uid in (vendedor_id, comprador_id);
  if v_v.id is null then
    raise exception 'Sin acceso al trato' using errcode = 'insufficient_privilege';
  end if;
  v_otro := case when v_v.vendedor_id = v_uid then v_v.comprador_id else v_v.vendedor_id end;

  if v_v.vendida_en < now() - interval '14 days' then
    raise exception 'Ya pasaron los 14 días para calificar'
      using errcode = 'check_violation', hint = 'plazo_vencido';
  end if;

  if p_estrellas is null or p_estrellas not between 1 and 5 then
    raise exception 'Elige de 1 a 5 estrellas'
      using errcode = 'check_violation', hint = 'estrellas_invalidas';
  end if;

  if v_comentario is not null and char_length(v_comentario) > 200 then
    raise exception 'El comentario es muy largo'
      using errcode = 'check_violation', hint = 'comentario_largo';
  end if;
  if v_comentario is not null
     and v_comentario !~ '^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,()/#+:%°$¿?¡!\n-]*$' then
    raise exception 'El comentario tiene caracteres no permitidos'
      using errcode = 'check_violation', hint = 'comentario_caracteres';
  end if;

  insert into public.calificaciones (venta_id, autor_id, calificado_id, estrellas, comentario)
  values (p_venta, v_uid, v_otro, p_estrellas, v_comentario)
  on conflict (venta_id, autor_id) do nothing
  returning id into v_id;

  if v_id is null then
    raise exception 'Ya calificaste este trato'
      using errcode = 'check_violation', hint = 'calificacion_duplicada';
  end if;
  return v_id;
end;
$$;

revoke all on function public.calificar(uuid, integer, text) from public, anon;
grant execute on function public.calificar(uuid, integer, text) to authenticated;

-- ---------------------------------------------------------------------
-- 7. tratos_por_calificar: mis tratos de los últimos 14 días que todavía
--    no califico. security invoker: RLS deja ver solo mis ventas.
-- ---------------------------------------------------------------------
drop function if exists public.tratos_por_calificar();

create function public.tratos_por_calificar()
returns table (
  venta_id            uuid,
  conversacion_id     uuid,
  publicacion_id      uuid,
  publicacion_titulo  text,
  publicacion_foto    text,
  soy_vendedor        boolean,
  otro_id             uuid,
  otro_nombre         text,
  otro_foto_url       text,
  vendida_en          timestamptz,
  vence_en            timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select v.id, v.conversacion_id, v.publicacion_id, p.titulo, p.fotos[1],
         v.vendedor_id = (select auth.uid()),
         o.id, o.nombre_mostrar, o.foto_url,
         v.vendida_en, v.vendida_en + interval '14 days'
    from public.ventas v
    join public.publicaciones p on p.id = v.publicacion_id
    join public.usuarios o
      on o.id = case when v.vendedor_id = (select auth.uid()) then v.comprador_id else v.vendedor_id end
   where (select auth.uid()) in (v.vendedor_id, v.comprador_id)
     and v.vendida_en >= now() - interval '14 days'
     and not exists (select 1 from public.calificaciones k
                      where k.venta_id = v.id and k.autor_id = (select auth.uid()))
   order by v.vendida_en desc, v.id
   limit 50;
$$;

revoke all on function public.tratos_por_calificar() from public, anon;
grant execute on function public.tratos_por_calificar() to authenticated;

-- ---------------------------------------------------------------------
-- 8. reputacion_usuario: el resumen de reputación de cualquier estudiante.
--    Solo cuántas calificaciones de cada estrella tiene (nunca quién ni
--    qué comentario). security definer porque los demás no pueden leer
--    las calificaciones una por una (RLS). Siempre regresa una fila
--    (con ceros si todavía no tiene calificaciones).
-- ---------------------------------------------------------------------
drop function if exists public.reputacion_usuario(uuid);

create function public.reputacion_usuario(p_usuario uuid)
returns table (
  usuario_id  uuid,
  total       integer,
  una         integer,
  dos         integer,
  tres        integer,
  cuatro      integer,
  cinco       integer
)
language sql
stable
security definer
set search_path = ''
as $$
  select p_usuario,
         count(k.id)::integer,
         count(k.id) filter (where k.estrellas = 1)::integer,
         count(k.id) filter (where k.estrellas = 2)::integer,
         count(k.id) filter (where k.estrellas = 3)::integer,
         count(k.id) filter (where k.estrellas = 4)::integer,
         count(k.id) filter (where k.estrellas = 5)::integer
    from public.calificaciones k
   where k.calificado_id = p_usuario
     and auth.uid() is not null;
$$;

revoke all on function public.reputacion_usuario(uuid) from public, anon;
grant execute on function public.reputacion_usuario(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 9. calificaciones_recibidas: las que yo recibí, las más nuevas primero,
--    por páginas (cursor created_at, id; máx. 50). Con el nombre de quien
--    me calificó y el título de la publicación del trato.
-- ---------------------------------------------------------------------
drop function if exists public.calificaciones_recibidas(timestamptz, uuid, integer);

create function public.calificaciones_recibidas(
  p_antes_de timestamptz default null,
  p_antes_id uuid        default null,
  p_limite   integer     default 20
)
returns table (
  id                  uuid,
  estrellas           smallint,
  comentario          text,
  created_at          timestamptz,
  autor_id            uuid,
  autor_nombre        text,
  autor_foto_url      text,
  publicacion_titulo  text,
  como_vendedor       boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select k.id, k.estrellas, k.comentario, k.created_at,
         a.id, a.nombre_mostrar, a.foto_url,
         p.titulo,
         v.vendedor_id = k.calificado_id
    from public.calificaciones k
    join public.ventas v        on v.id = k.venta_id
    join public.publicaciones p on p.id = v.publicacion_id
    join public.usuarios a      on a.id = k.autor_id
   where k.calificado_id = (select auth.uid())
     and (
       p_antes_de is null
       or (k.created_at, k.id) <
          (p_antes_de, coalesce(p_antes_id, 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid))
     )
   order by k.created_at desc, k.id desc
   limit least(greatest(coalesce(p_limite, 20), 1), 50);
$$;

revoke all on function public.calificaciones_recibidas(timestamptz, uuid, integer) from public, anon;
grant execute on function public.calificaciones_recibidas(timestamptz, uuid, integer) to authenticated;

notify pgrst, 'reload schema';

commit;

-- ---------------------------------------------------------------------
-- Comprobación después de aplicarla (para José Luis): debe regresar
-- 8 filas, todas con "sí".
-- ---------------------------------------------------------------------
-- select 'tabla ventas' as que, case when to_regclass('public.ventas') is not null then 'sí' else 'NO' end as listo
-- union all select 'tabla calificaciones', case when to_regclass('public.calificaciones') is not null then 'sí' else 'NO' end
-- union all select 'función marcar_vendida', case when to_regprocedure('public.marcar_vendida(uuid,uuid)') is not null then 'sí' else 'NO' end
-- union all select 'función calificar', case when to_regprocedure('public.calificar(uuid,integer,text)') is not null then 'sí' else 'NO' end
-- union all select 'función reputacion_usuario', case when to_regprocedure('public.reputacion_usuario(uuid)') is not null then 'sí' else 'NO' end
-- union all select 'función tratos_por_calificar', case when to_regprocedure('public.tratos_por_calificar()') is not null then 'sí' else 'NO' end
-- union all select 'RLS en calificaciones', case when (select relrowsecurity from pg_class where oid = 'public.calificaciones'::regclass) then 'sí' else 'NO' end
-- union all select 'punto de encuentro (HU-08) aplicado', case when to_regclass('public.encuentros') is not null then 'sí' else 'NO' end;
--
-- KPI del issue #8 (calificación promedio mayor a 4.2/5): promedio de todas
-- las calificaciones y si ya se cumple.
-- select count(*) as calificaciones,
--        round(avg(estrellas), 2) as promedio,
--        case when count(*) = 0 then 'sin datos'
--             when avg(estrellas) > 4.2 then 'sí se cumple' else 'todavía no' end as kpi
-- from public.calificaciones;
