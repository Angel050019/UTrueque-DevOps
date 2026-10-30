-- =====================================================================
-- UTrueque · Sprint 6 · Seguridad: caracteres permitidos
-- Migración: la base rechaza caracteres especiales que no hacen falta en
-- el título y la descripción de las publicaciones y en el nombre a
-- mostrar del perfil (validación de entrada con lista de permitidos).
--
-- Cómo aplicarla: Supabase → SQL Editor → pegar TODO el archivo → Run.
-- Es idempotente: se puede volver a correr sin romper nada.
-- Requiere las migraciones de HU-02 y HU-03. No depende de la de HU-06.
-- No cambia tablas, columnas, datos ni las funciones del Feed.
--
-- Qué se permite (lo mismo que revisa la app):
--   · Título:      letras (con acentos y ñ), números, espacios y
--                  . , - ( ) / # + : % ° $ ¿ ? ¡ !
--   · Descripción: lo mismo que el título, más saltos de línea.
--   · Nombre a mostrar: letras (con acentos y ñ), espacios, punto y guion.
--   Todo lo demás se rechaza: < > { } [ ] \ | ` ~ ^ = * & @ _ ; ' "
--   emojis y caracteres invisibles.
--
-- IMPORTANTE: la regla solo se revisa cuando el texto es NUEVO o CAMBIA.
-- Así, una publicación vieja con un signo que ya no se permite se puede
-- seguir reservando, vendiendo o borrando; solo hay que corregir el texto
-- si se edita. Por eso se usan triggers y no un "check" (un check se
-- revisa en cada cambio de la fila, aunque no se toque el texto).
--
-- Cada rechazo llega como error 23514 con una pista (hint) fija para que
-- la app marque el campo correcto, sin detalles internos:
--   titulo_caracteres | descripcion_caracteres | nombre_caracteres
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. SEGURIDAD: publicaciones (título y descripción)
-- ---------------------------------------------------------------------
create or replace function public.publicaciones_validar_caracteres()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (tg_op = 'INSERT' or new.titulo is distinct from old.titulo)
     and new.titulo !~ '^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,()/#+:%°$¿?¡!-]*$' then
    raise exception 'El título tiene caracteres no permitidos'
      using errcode = 'check_violation', hint = 'titulo_caracteres';
  end if;

  if (tg_op = 'INSERT' or new.descripcion is distinct from old.descripcion)
     and new.descripcion !~ '^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,()/#+:%°$¿?¡!\n-]*$' then
    raise exception 'La descripción tiene caracteres no permitidos'
      using errcode = 'check_violation', hint = 'descripcion_caracteres';
  end if;

  return new;
end;
$$;

drop trigger if exists publicaciones_validar_caracteres on public.publicaciones;
create trigger publicaciones_validar_caracteres
  before insert or update of titulo, descripcion on public.publicaciones
  for each row execute function public.publicaciones_validar_caracteres();

-- ---------------------------------------------------------------------
-- 2. SEGURIDAD: perfil (nombre a mostrar)
--    Al registrarse, el perfil nace sin nombre (null): eso se permite.
-- ---------------------------------------------------------------------
create or replace function public.usuarios_validar_caracteres()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.nombre_mostrar is not null
     and (tg_op = 'INSERT' or new.nombre_mostrar is distinct from old.nombre_mostrar)
     and new.nombre_mostrar !~ '^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ .-]*$' then
    raise exception 'El nombre tiene caracteres no permitidos'
      using errcode = 'check_violation', hint = 'nombre_caracteres';
  end if;
  return new;
end;
$$;

drop trigger if exists usuarios_validar_caracteres on public.usuarios;
create trigger usuarios_validar_caracteres
  before insert or update of nombre_mostrar on public.usuarios
  for each row execute function public.usuarios_validar_caracteres();

commit;

-- ---------------------------------------------------------------------
-- Comprobación después de aplicarla: debe regresar 2 filas con "sí".
-- ---------------------------------------------------------------------
-- select tgname as trigger, 'sí' as existe
-- from pg_trigger
-- where tgname in ('publicaciones_validar_caracteres', 'usuarios_validar_caracteres');
--
-- Para saber cuántos textos viejos ya no cumplen la regla (no se borran
-- ni se cambian; solo se piden corregir si se editan):
-- select count(*) filter (where titulo !~ '^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,()/#+:%°$¿?¡!-]*$') as titulos,
--        count(*) filter (where descripcion !~ '^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,()/#+:%°$¿?¡!\n-]*$') as descripciones
-- from public.publicaciones;
