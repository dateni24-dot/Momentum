-- =============================================
-- MOMENTUM APP - Fix trigger set_updated_at
-- El trigger original insertaba en user_avatar en cada UPDATE de user,
-- acumulando registros basura que rompían la selección del avatar activo.
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- 1. Corregir el trigger: solo actualizar updated_at, sin tocar user_avatar
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- 2. Limpiar registros duplicados de user_avatar sin current = true
--    (los creados erróneamente por el trigger anterior)
--    Mantiene SOLO un registro por (user_id, avatar_id):
--      · Si tiene current = true → se queda
--      · Si tiene current = false → se queda el más reciente
--      · El resto se elimina
DELETE FROM public.user_avatar
WHERE id IN (
  SELECT id FROM (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY user_id, avatar_id
             ORDER BY
               CASE WHEN current = true THEN 0 ELSE 1 END,
               created_at DESC
           ) AS rn
    FROM public.user_avatar
  ) ranked
  WHERE rn > 1
);

-- 3. Verificación: cada usuario debe tener exactamente un registro por avatar
SELECT user_id, avatar_id, count(*) as total
FROM public.user_avatar
GROUP BY user_id, avatar_id
HAVING count(*) > 1;
-- Si esta query no devuelve filas, la limpieza fue exitosa.
