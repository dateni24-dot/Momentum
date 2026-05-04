-- =============================================
-- MOMENTUM APP - Sistema de Rachas
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- 1. Añadir columnas de racha a la tabla user
alter table public.user
  add column if not exists streak_days         int  not null default 0,
  add column if not exists streak_record       int  not null default 0,
  add column if not exists last_completed_date date null;

-- 2. Función atómica que:
--    a) Actualiza la racha del usuario
--    b) Aplica el multiplicador de XP según la racha
--    c) Incrementa el XP del avatar
--    d) Devuelve los datos necesarios para la UI
--
--    Multiplicadores (Opción A + récord):
--      streak  1-6  → ×1.0
--      streak  7-13 → ×1.25
--      streak 14-29 → ×1.5
--      streak 30+   → ×2.0
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
  v_last_date   date;
  v_streak      int;
  v_record      int;
  v_today       date    := current_date;
  v_multiplier  numeric;
  v_final_xp    int;
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

  -- Incrementar XP del avatar activo
  update public.user_avatar
  set current_xp = current_xp + v_final_xp
  where user_id = p_user_id;

  -- Devolver datos para la UI
  return jsonb_build_object(
    'xp_awarded',    v_final_xp,
    'multiplier',    v_multiplier,
    'streak_days',   v_streak,
    'streak_record', v_record,
    'is_milestone',  v_streak = any(array[7, 14, 30])
  );
end;
$$;

-- 3. Política RLS: permitir que el usuario lea sus propias columnas de racha
--    (ya existe política de select en user, esto es por si acaso)
drop policy if exists "User lee su propio perfil" on public.user;
create policy "User lee su propio perfil"
  on public.user for select
  using (auth.uid() = id);
