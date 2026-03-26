-- =============================================
-- MOMENTUM APP - Supabase SQL mínimo para auth
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- 1. Tabla de perfiles vinculada a auth.users
--    auth.users la gestiona Supabase automáticamente (email, password, etc.)
--    Aquí guardamos los datos extra del usuario de la app.

create table public.profiles (
  id          uuid          not null references auth.users on delete cascade,
  username    varchar(10)   not null,
  coins       int           not null default 0,
  created_at  timestamptz   not null default now(),
  updated_at  timestamptz   not null default now(),
  constraint profiles_pkey primary key (id),
  constraint profiles_username_key unique (username),
  constraint profiles_coins_check check (coins >= 0)
);

-- 2. Seguridad a nivel de fila (RLS)
alter table public.profiles enable row level security;

-- El usuario solo puede leer su propio perfil
create policy "Perfil propio lectura"
  on public.profiles for select
  using (auth.uid() = id);

-- El usuario solo puede insertar su propio perfil
create policy "Perfil propio insercion"
  on public.profiles for insert
  with check (auth.uid() = id);

-- El usuario solo puede actualizar su propio perfil
create policy "Perfil propio actualizacion"
  on public.profiles for update
  using (auth.uid() = id);

-- 3. Trigger: crea el perfil automáticamente al registrarse
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', 'user_' || substring(new.id::text from 1 for 6))
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
