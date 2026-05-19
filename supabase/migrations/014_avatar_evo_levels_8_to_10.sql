-- =============================================
-- MOMENTUM APP - Rellenar niveles 8, 9 y 10 en avatar_evo
--
-- Los assets PNG existen (lvl1..lvl10) pero la BBDD solo tenía hasta
-- el nivel 7 por avatar. El carrusel de la tienda saltaba el lvl10
-- porque la fila no estaba en avatar_evo.
--
-- Progresión de max_xp (continuando la curva 2x existente):
--   lv7 = 6400  →  lv8 = 12800  →  lv9 = 25600  →  lv10 = 51200
--
-- Convención de evo_img por avatar (los nombres reales en assets/):
--   Gymbro          → Gymbro_lvlN
--   Healthy Woman   → chica_lvlN
--   Errante Viajero → ErranteViajero_lvlN
--
-- Ejecutar en: Supabase > SQL Editor. Es idempotente: solo inserta los
-- niveles que falten, no toca los existentes.
-- =============================================


-- ─────────────────────────────────────────────────────────────────────
-- PASO 1: Tabla auxiliar con la progresión deseada
-- ─────────────────────────────────────────────────────────────────────

WITH wanted(level, max_xp) AS (
  VALUES
    (8::int,  12800::int),
    (9::int,  25600::int),
    (10::int, 51200::int)
),
prefijo_por_avatar AS (
  SELECT
    avatar_id,
    avatar_name,
    CASE avatar_name
      WHEN 'Gymbro'          THEN 'Gymbro_lvl'
      WHEN 'Healthy Woman'   THEN 'chica_lvl'
      WHEN 'Errante Viajero' THEN 'ErranteViajero_lvl'
      ELSE avatar_name || '_lvl'   -- fallback genérico
    END AS prefix
  FROM public.avatars
)
INSERT INTO public.avatar_evo (avatar_id, level, evo_img, max_xp)
SELECT
  p.avatar_id,
  w.level,
  p.prefix || w.level,
  w.max_xp
FROM prefijo_por_avatar p
CROSS JOIN wanted w
WHERE NOT EXISTS (
  SELECT 1 FROM public.avatar_evo ae
  WHERE ae.avatar_id = p.avatar_id AND ae.level = w.level
);


-- ─────────────────────────────────────────────────────────────────────
-- PASO 2: Verificación
-- Debe mostrar 10 niveles por avatar, con evo_img acorde a la
-- convención de nombres de los ficheros PNG.
-- ─────────────────────────────────────────────────────────────────────

SELECT a.avatar_name, ae.level, ae.evo_img, ae.max_xp
FROM public.avatar_evo ae
JOIN public.avatars a ON a.avatar_id = ae.avatar_id
ORDER BY a.avatar_name, ae.level;
