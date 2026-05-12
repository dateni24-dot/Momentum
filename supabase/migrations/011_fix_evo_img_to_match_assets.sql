-- =============================================
-- MOMENTUM APP - Reasignar evo_img a los nombres reales de los assets
--
-- La migration 010 normalizó evo_img usando `avatar_name`, pero los PNG
-- en assets/avatars/ tienen otros prefijos que no siempre coinciden con
-- el nombre del avatar mostrado:
--
--   avatar_name        prefijo del fichero PNG
--   ─────────────      ────────────────────────
--   Healthy Woman      chica
--   Errante Viajero    ErranteViajero      (sin espacio)
--   Gymbro             Gymbro              (ya coincidía)
--   Stickman           stickman            (si existe)
--
-- Ejecutar en: Supabase > SQL Editor. Es idempotente.
-- =============================================

UPDATE public.avatar_evo ae
SET evo_img = 'chica_lvl' || ae.level
FROM public.avatars a
WHERE ae.avatar_id = a.avatar_id
  AND a.avatar_name = 'Healthy Woman';

UPDATE public.avatar_evo ae
SET evo_img = 'ErranteViajero_lvl' || ae.level
FROM public.avatars a
WHERE ae.avatar_id = a.avatar_id
  AND a.avatar_name = 'Errante Viajero';

UPDATE public.avatar_evo ae
SET evo_img = 'Gymbro_lvl' || ae.level
FROM public.avatars a
WHERE ae.avatar_id = a.avatar_id
  AND a.avatar_name = 'Gymbro';

UPDATE public.avatar_evo ae
SET evo_img = 'stickman_lv' || ae.level
FROM public.avatars a
WHERE ae.avatar_id = a.avatar_id
  AND a.avatar_name = 'Stickman';

-- Verificación: cada fila debe tener un evo_img que coincida con un
-- fichero real en assets/avatars/<evo_img>.PNG
SELECT a.avatar_name, ae.level, ae.evo_img
FROM public.avatar_evo ae
JOIN public.avatars a ON a.avatar_id = ae.avatar_id
ORDER BY a.avatar_name, ae.level;
