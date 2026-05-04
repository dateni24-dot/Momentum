-- =============================================
-- MOMENTUM APP - Sistema de XP para avatares
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- 1. Añadir current_xp a user_avatar (si no existe)
alter table public.user_avatar
  add column if not exists current_xp int not null default 0;

-- 2. Función atómica: incrementa XP y sube de nivel si corresponde
create or replace function public.increment_avatar_xp(p_user_id uuid, p_amount int)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current_xp     int;
  v_max_xp         int;
  v_avatar_id      int;
  v_current_evo_id int;
  v_current_level  int;
  v_next_evo_id    int;
begin
  select ua.current_xp, ua.avatar_id, ua.avatar_evo_id, ae.max_xp, ae.level
  into v_current_xp, v_avatar_id, v_current_evo_id, v_max_xp, v_current_level
  from public.user_avatar ua
  join public.avatar_evo ae on ae.id = ua.avatar_evo_id
  where ua.user_id = p_user_id;

  v_current_xp := v_current_xp + p_amount;

  if v_current_xp >= v_max_xp then
    -- Buscar el siguiente nivel del mismo avatar
    select id into v_next_evo_id
    from public.avatar_evo
    where avatar_id = v_avatar_id and level = v_current_level + 1
    limit 1;

    if v_next_evo_id is not null then
      -- Subir de nivel: restar la XP del nivel anterior y cambiar evo
      update public.user_avatar
      set current_xp    = v_current_xp - v_max_xp,
          avatar_evo_id = v_next_evo_id
      where user_id = p_user_id;
    else
      -- Nivel máximo alcanzado: fijar en max_xp - 1
      update public.user_avatar
      set current_xp = v_max_xp - 1
      where user_id = p_user_id;
    end if;
  else
    update public.user_avatar
    set current_xp = v_current_xp
    where user_id = p_user_id;
  end if;
end;
$$;

-- 3. Política UPDATE que faltaba en user_habit (necesaria para started_at y completed)
drop policy if exists "UserHabit actualizacion propia" on public.user_habit;

create policy "UserHabit actualizacion propia"
  on public.user_habit for update
  using (auth.uid() = user_id);
