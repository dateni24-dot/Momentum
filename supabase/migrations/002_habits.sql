-- =============================================
-- MOMENTUM APP - RLS y políticas para habit y user_habit
-- Las tablas habit y user_habit ya existen en Supabase.
-- Este script solo añade RLS y políticas de seguridad.
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- 1. RLS en tabla habit
alter table public.habit enable row level security;

drop policy if exists "Habit lectura autenticados" on public.habit;
drop policy if exists "Habit insercion propia"     on public.habit;
drop policy if exists "Habit actualizacion propia" on public.habit;
drop policy if exists "Habit eliminacion propia"   on public.habit;

-- Cualquier usuario autenticado puede leer todos los hábitos
create policy "Habit lectura autenticados"
  on public.habit for select
  to authenticated
  using (true);

-- Solo puede insertar un usuario autenticado
create policy "Habit insercion propia"
  on public.habit for insert
  to authenticated
  with check (true);

-- Solo puede actualizar si el hábito le pertenece (existe en user_habit)
create policy "Habit actualizacion propia"
  on public.habit for update
  to authenticated
  using (
    exists (
      select 1 from public.user_habit
      where user_habit.habit_id = habit.habit_id
        and user_habit.user_id  = auth.uid()
    )
  );

-- Solo puede eliminar si el hábito le pertenece
create policy "Habit eliminacion propia"
  on public.habit for delete
  to authenticated
  using (
    exists (
      select 1 from public.user_habit
      where user_habit.habit_id = habit.habit_id
        and user_habit.user_id  = auth.uid()
    )
  );

-- 2. RLS en tabla user_habit
alter table public.user_habit enable row level security;

drop policy if exists "UserHabit lectura propia"    on public.user_habit;
drop policy if exists "UserHabit insercion propia"  on public.user_habit;
drop policy if exists "UserHabit eliminacion propia" on public.user_habit;

create policy "UserHabit lectura propia"
  on public.user_habit for select
  using (auth.uid() = user_id);

create policy "UserHabit insercion propia"
  on public.user_habit for insert
  with check (auth.uid() = user_id);

create policy "UserHabit eliminacion propia"
  on public.user_habit for delete
  using (auth.uid() = user_id);

-- =============================================
-- VERIFICACIÓN:
-- SELECT * FROM public.habit;        -> hábitos creados
-- SELECT * FROM public.user_habit;   -> relaciones usuario-hábito
-- =============================================
