-- =============================================
-- MOMENTUM APP - Fix evo_img de Gymbro
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- 1. DIAGNÓSTICO: Ver qué evo_img tiene Gymbro actualmente
SELECT ae.id, ae.level, ae.evo_img, ae.avatar_id, a.avatar_name
FROM public.avatar_evo ae
JOIN public.avatars a ON a.avatar_id = ae.avatar_id
WHERE a.avatar_name = 'Gymbro'
ORDER BY ae.level;

-- 2. FIX: Asignar el evo_img correcto a cada nivel de Gymbro
--    (solo ejecutar si el diagnóstico muestra evo_img = 'chica_lvl*')
UPDATE public.avatar_evo ae
SET evo_img = 'Gymbro_lvl' || ae.level
FROM public.avatars a
WHERE ae.avatar_id = a.avatar_id
  AND a.avatar_name = 'Gymbro';

-- 3. VERIFICACIÓN: Confirmar que quedó correcto
SELECT ae.id, ae.level, ae.evo_img
FROM public.avatar_evo ae
JOIN public.avatars a ON a.avatar_id = ae.avatar_id
WHERE a.avatar_name = 'Gymbro'
ORDER BY ae.level;
