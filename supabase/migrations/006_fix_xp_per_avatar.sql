-- =============================================
-- MOMENTUM APP - Fix XP por avatar (bug: XP compartida entre todos)
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- Reescribir complete_habit_with_streak para:
--   1. Solo actualizar el avatar ACTIVO (current = true)
--   2. Incluir lógica de level-up
--   3. Devolver leveled_up en la respuesta
create or replace function public.complete_habit_with_streak(
  p_user_id uuid,
  p_base_xp  int
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_last_date      date;
  v_streak         int;
  v_record         int;
  v_today          date    := current_date;
  v_multiplier     numeric;
  v_final_xp       int;
  v_current_xp     int;
  v_max_xp         int;
  v_current_evo_id int;
  v_current_level  int;
  v_avatar_id      int;
  v_next_evo_id    int;
  v_leveled_up     boolean := false;
begin
  -- Obtener estado actual de racha
  select last_completed_date, streak_days, streak_record
  into   v_last_date, v_streak, v_record
  from   public.user
  where  id = p_user_id;

  -- Lógica de racha
  if v_last_date = v_today then
    -- Ya completó algo hoy: la racha no cambia (pero sí da XP)
    null;
  elsif v_last_date = v_today - interval '1 day' then
    -- Completó ayer: racha continúa
    v_streak := v_streak + 1;
  else
    -- Primer uso o racha rota
    v_streak := 1;
  end if;

  -- Actualizar récord histórico
  if v_streak > v_record then
    v_record := v_streak;
  end if;

  -- Persistir racha y fecha
  update public.user
  set streak_days          = v_streak,
      streak_record        = v_record,
      last_completed_date  = v_today,
      updated_at           = now()
  where id = p_user_id;

  -- Calcular multiplicador según racha actual
  v_multiplier := case
    when v_streak >= 30 then 2.0
    when v_streak >= 14 then 1.5
    when v_streak >= 7  then 1.25
    else                     1.0
  end;

  v_final_xp := floor(p_base_xp * v_multiplier);

  -- Obtener estado del avatar ACTIVO (current = true)
  select ua.current_xp, ua.avatar_id, ua.avatar_evo_id, ae.max_xp, ae.level
  into v_current_xp, v_avatar_id, v_current_evo_id, v_max_xp, v_current_level
  from public.user_avatar ua
  join public.avatar_evo ae on ae.id = ua.avatar_evo_id
  where ua.user_id = p_user_id
    and ua.current = true;

  v_current_xp := v_current_xp + v_final_xp;

  -- Comprobar si hay level-up
  if v_current_xp >= v_max_xp then
    select id into v_next_evo_id
    from public.avatar_evo
    where avatar_id = v_avatar_id and level = v_current_level + 1
    limit 1;

    if v_next_evo_id is not null then
      -- Subir de nivel: restar XP del nivel anterior y cambiar evolución
      update public.user_avatar
      set current_xp    = v_current_xp - v_max_xp,
          avatar_evo_id = v_next_evo_id
      where user_id = p_user_id
        and current = true;
      v_leveled_up := true;
    else
      -- Nivel máximo alcanzado: fijar en max_xp - 1
      update public.user_avatar
      set current_xp = v_max_xp - 1
      where user_id = p_user_id
        and current = true;
    end if;
  else
    -- Solo incrementar XP del avatar activo
    update public.user_avatar
    set current_xp = v_current_xp
    where user_id = p_user_id
      and current = true;
  end if;

  -- Devolver datos para la UI
  return jsonb_build_object(
    'xp_awarded',    v_final_xp,
    'multiplier',    v_multiplier,
    'streak_days',   v_streak,
    'streak_record', v_record,
    'is_milestone',  v_streak = any(array[7, 14, 30]),
    'leveled_up',    v_leveled_up
  );
end;
$$;

-- Arreglar también increment_avatar_xp para que filtre por avatar activo
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
  where ua.user_id = p_user_id
    and ua.current = true;

  v_current_xp := v_current_xp + p_amount;

  if v_current_xp >= v_max_xp then
    select id into v_next_evo_id
    from public.avatar_evo
    where avatar_id = v_avatar_id and level = v_current_level + 1
    limit 1;

    if v_next_evo_id is not null then
      update public.user_avatar
      set current_xp    = v_current_xp - v_max_xp,
          avatar_evo_id = v_next_evo_id
      where user_id = p_user_id
        and current = true;
    else
      update public.user_avatar
      set current_xp = v_max_xp - 1
      where user_id = p_user_id
        and current = true;
    end if;
  else
    update public.user_avatar
    set current_xp = v_current_xp
    where user_id = p_user_id
      and current = true;
  end if;
end;
$$;
