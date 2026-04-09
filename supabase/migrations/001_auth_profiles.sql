-- =============================================
-- MOMENTUM APP - Supabase SQL para tabla user
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- 1. Eliminar trigger y función anteriores (si existen)
drop function if exists public.handle_new_user() cascade;

-- 2. Seguridad a nivel de fila (RLS) sobre la tabla user existente
alter table public."user" enable row level security;

-- Eliminar políticas previas si existen para evitar duplicados
drop policy if exists "Perfil propio lectura" on public."user";
drop policy if exists "Perfil propio insercion" on public."user";
drop policy if exists "Perfil propio actualizacion" on public."user";
drop policy if exists "Users can view own profile" on public."user";
drop policy if exists "Users can update own profile" on public."user";

-- El usuario solo puede leer su propio registro
create policy "Perfil propio lectura"
  on public."user" for select
  -- auth.uid() devuelve el ID del usuario autenticado, que debe coincidir con el ID del registro
  using (auth.uid() = id);

-- El sistema (trigger SECURITY DEFINER) puede insertar al registrarse
create policy "Perfil propio insercion"
  on public."user" for insert
  with check (auth.uid() = id);

-- El usuario solo puede actualizar su propio registro
create policy "Perfil propio actualizacion"
  on public."user" for update
  -- auth.uid() devuelve el ID del usuario autenticado, que debe coincidir con el ID del registro
  using (auth.uid() = id);

-- 3. Trigger: crea la fila en user automáticamente al registrarse
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public."user" (id, username, coins, created_at, updated_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', 'user_' || substring(new.id::text from 1 for 6)),
    0,
    now(),
    now()
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 4. Función para actualizar updated_at automáticamente
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger user_updated_at
  before update on public."user"
  for each row execute procedure public.set_updated_at();

-- =============================================
-- VERIFICACIÓN: tras ejecutar, deberías ver:
-- SELECT * FROM public."user";  -> vacía, se llenará al registrarse
-- =============================================
