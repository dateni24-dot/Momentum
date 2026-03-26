-- =============================================
-- MOMENTUM APP - Supabase SQL para tabla users
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- 1. Eliminar trigger y función anteriores (si existen)
drop function if exists public.handle_new_user() cascade;

-- 2. Seguridad a nivel de fila (RLS) sobre la tabla users existente
alter table public.users enable row level security;

-- Eliminar políticas previas si existen para evitar duplicados
drop policy if exists "Perfil propio lectura" on public.users;
drop policy if exists "Perfil propio insercion" on public.users;
drop policy if exists "Perfil propio actualizacion" on public.users;
drop policy if exists "Users can view own profile" on public.users;
drop policy if exists "Users can update own profile" on public.users;

-- El usuario solo puede leer su propio registro
create policy "Perfil propio lectura"
  on public.users for select
  using (auth.uid() = id);

-- El sistema (trigger SECURITY DEFINER) puede insertar al registrarse
create policy "Perfil propio insercion"
  on public.users for insert
  with check (auth.uid() = id);

-- El usuario solo puede actualizar su propio registro
create policy "Perfil propio actualizacion"
  on public.users for update
  using (auth.uid() = id);

-- 3. Trigger: crea la fila en users automáticamente al registrarse
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, username, coins, created_at, updated_at)
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

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

-- =============================================
-- VERIFICACIÓN: tras ejecutar, deberías ver:
-- SELECT * FROM public.profiles;  -> vacía, se llenará al registrarse
-- =============================================
