-- =============================================
-- MOMENTUM APP - Diagnóstico y fix de avatar_evo_id incorrecto
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- PASO 1: DIAGNÓSTICO
-- Muestra todos los user_avatar con el evo_img que están usando actualmente
-- y si ese evo pertenece al avatar correcto o al incorrecto.
SELECT
  ua.id               AS user_avatar_id,
  ua.user_id,
  ua.avatar_id        AS ua_avatar_id,
  a.avatar_name,
  ua.avatar_evo_id,
  ae.evo_img          AS evo_img_actual,
  ae.avatar_id        AS evo_pertenece_a_avatar,
  ae.level            AS nivel_actual,
  ua.current_xp,
  ua.current,
  CASE
    WHEN ae.avatar_id = ua.avatar_id THEN 'OK'
    ELSE 'INCORRECTO - apunta a evo de otro avatar'
  END AS estado
FROM public.user_avatar ua
JOIN public.avatars a    ON a.avatar_id = ua.avatar_id
JOIN public.avatar_evo ae ON ae.id      = ua.avatar_evo_id
ORDER BY ua.user_id, ua.current DESC;

-- =============================================
-- Si el PASO 1 muestra filas con estado = 'INCORRECTO', ejecuta el PASO 2:
-- =============================================

-- PASO 2: FIX
-- Para cada user_avatar cuyo avatar_evo_id apunta al evo de otro avatar,
-- lo redirige al evo del avatar correcto en el mismo nivel.
UPDATE public.user_avatar ua
SET avatar_evo_id = correct_ae.id
FROM
  public.avatar_evo wrong_ae,
  public.avatar_evo correct_ae
WHERE
  ua.avatar_evo_id   = wrong_ae.id
  AND wrong_ae.avatar_id != ua.avatar_id          -- evo apunta al avatar equivocado
  AND correct_ae.avatar_id = ua.avatar_id         -- evo correcto para este avatar
  AND correct_ae.level     = wrong_ae.level;      -- mismo nivel

-- PASO 3: VERIFICACIÓN
-- Debe mostrar solo filas con estado = 'OK'
SELECT
  ua.id,
  a.avatar_name,
  ae.evo_img,
  ae.level,
  ua.current,
  CASE
    WHEN ae.avatar_id = ua.avatar_id THEN 'OK'
    ELSE 'INCORRECTO'
  END AS estado
FROM public.user_avatar ua
JOIN public.avatars a     ON a.avatar_id = ua.avatar_id
JOIN public.avatar_evo ae ON ae.id       = ua.avatar_evo_id
ORDER BY ua.user_id, ua.current DESC;
