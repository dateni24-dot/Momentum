-- =============================================
-- MOMENTUM APP - Timer para hábitos
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- Añade started_at a user_habit para persistir el inicio del temporizador
alter table public.user_habit
  add column if not exists started_at timestamptz null;
