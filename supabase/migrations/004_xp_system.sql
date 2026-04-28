-- =============================================
-- MOMENTUM APP - Sistema de XP para avatares
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- 1. Añadir current_xp a user_avatar (si no existe)
alter table public.user_avatar
  add column if not exists current_xp int not null default 0;

-- 2. Función atómica para incrementar la XP del avatar activo del usuario
create or replace function public.increment_avatar_xp(p_user_id uuid, p_amount int)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.user_avatar
  set current_xp = current_xp + p_amount,
      updated_at = now()
  where user_id = p_user_id;
end;
$$;

-- 3. Política UPDATE que faltaba en user_habit (necesaria para started_at y completed)
drop policy if exists "UserHabit actualizacion propia" on public.user_habit;

create policy "UserHabit actualizacion propia"
  on public.user_habit for update
  using (auth.uid() = user_id);
