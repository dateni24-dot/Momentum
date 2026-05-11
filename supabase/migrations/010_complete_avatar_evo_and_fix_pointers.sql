-- =============================================
-- MOMENTUM APP - Fix definitivo del estado de avatares
--
-- Causa raíz: bugs antiguos (set_updated_at, complete_habit_with_streak e
-- increment_avatar_xp sin filtrar por current=true) dejaron filas en
-- user_avatar apuntando al avatar_evo equivocado. La migration 009 sólo
-- arregla los punteros si existe un evo del avatar correcto en el MISMO
-- nivel; si no existe (p.ej. Gymbro sólo tiene lv1 en BBDD), no fixea.
--
-- Esta migration:
--   1) Diagnostica el estado actual
--   2) Rellena los niveles que faltan en avatar_evo (Gymbro y cualquier
--      otro avatar incompleto), usando como plantilla los max_xp de un
--      avatar que sí los tenga.
--   3) Reaplica el fix de punteros (009) ahora que existen todos los evos
--   4) Verifica que todo quede en estado OK
--
-- Ejecutar en: Supabase > SQL Editor (todo seguido, es idempotente).
-- =============================================


-- ─────────────────────────────────────────────────────────────────────
-- PASO 1: DIAGNÓSTICO PREVIO
-- Mira estos resultados antes de continuar para entender el estado.
-- ─────────────────────────────────────────────────────────────────────

-- 1a. ¿Cuántos niveles tiene cada avatar en avatar_evo?
SELECT a.avatar_id, a.avatar_name, count(ae.id) AS niveles_definidos
FROM public.avatars a
LEFT JOIN public.avatar_evo ae ON ae.avatar_id = a.avatar_id
GROUP BY a.avatar_id, a.avatar_name
ORDER BY a.avatar_name;

-- 1b. ¿Qué evo_img tiene cada nivel de cada avatar?
SELECT a.avatar_name, ae.level, ae.evo_img, ae.max_xp
FROM public.avatar_evo ae
JOIN public.avatars a ON a.avatar_id = ae.avatar_id
ORDER BY a.avatar_name, ae.level;

-- 1c. Estado de cada user_avatar: ¿apunta al evo correcto?
SELECT
  ua.user_id,
  a.avatar_name        AS avatar_de_la_fila,
  ua.current,
  ua.current_xp,
  ae.level             AS nivel_evo_actual,
  ae.evo_img           AS evo_img_actual,
  a2.avatar_name       AS evo_pertenece_a,
  CASE WHEN ae.avatar_id = ua.avatar_id THEN 'OK'
       ELSE 'ROTO: apunta a evo de otro avatar' END AS estado
FROM public.user_avatar ua
JOIN public.avatars    a  ON a.avatar_id  = ua.avatar_id
JOIN public.avatar_evo ae ON ae.id        = ua.avatar_evo_id
JOIN public.avatars    a2 ON a2.avatar_id = ae.avatar_id
ORDER BY ua.user_id, ua.current DESC;


-- ─────────────────────────────────────────────────────────────────────
-- PASO 2: RELLENAR NIVELES QUE FALTAN EN avatar_evo
--
-- Si Gymbro (u otro avatar) tiene menos niveles que el avatar más
-- completo, insertamos los que falten copiando max_xp del template y
-- usando evo_img = '<AvatarName>_lvl<N>' (convención de los PNG).
-- ─────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_max_level int;
  v_template_avatar_id int;
BEGIN
  -- Máximo nivel definido en cualquier avatar (referencia objetivo)
  SELECT max(level) INTO v_max_level FROM public.avatar_evo;

  -- Avatar con más niveles, lo usamos como plantilla para max_xp
  SELECT avatar_id INTO v_template_avatar_id
  FROM public.avatar_evo
  GROUP BY avatar_id
  ORDER BY count(*) DESC, avatar_id ASC
  LIMIT 1;

  IF v_max_level IS NULL OR v_template_avatar_id IS NULL THEN
    RAISE NOTICE 'No hay avatar_evo definidos, nada que rellenar.';
    RETURN;
  END IF;

  -- Para cada avatar y nivel 1..v_max_level que no exista, insertarlo
  INSERT INTO public.avatar_evo (avatar_id, level, evo_img, max_xp)
  SELECT
    a.avatar_id,
    lvl.level,
    a.avatar_name || '_lvl' || lvl.level,
    template.max_xp
  FROM public.avatars a
  CROSS JOIN generate_series(1, v_max_level) AS lvl(level)
  LEFT JOIN public.avatar_evo existing
    ON existing.avatar_id = a.avatar_id AND existing.level = lvl.level
  LEFT JOIN public.avatar_evo template
    ON template.avatar_id = v_template_avatar_id AND template.level = lvl.level
  WHERE existing.id IS NULL
    AND template.max_xp IS NOT NULL;
END $$;


-- ─────────────────────────────────────────────────────────────────────
-- PASO 3: NORMALIZAR evo_img DE TODOS LOS AVATARES
--
-- Si por arrastre histórico algún avatar tiene evo_img con el nombre
-- de otro avatar (p.ej. Gymbro con evo_img = 'chica_lvl1'), lo corrige
-- a la convención '<AvatarName>_lvl<level>'. Sólo lo hace si el evo_img
-- actual NO empieza por el nombre del avatar al que pertenece.
-- ─────────────────────────────────────────────────────────────────────

UPDATE public.avatar_evo ae
SET evo_img = a.avatar_name || '_lvl' || ae.level
FROM public.avatars a
WHERE ae.avatar_id = a.avatar_id
  AND ae.evo_img NOT LIKE a.avatar_name || '%';


-- ─────────────────────────────────────────────────────────────────────
-- PASO 4: REDIRIGIR user_avatar.avatar_evo_id AL EVO CORRECTO
--
-- Para cada fila de user_avatar cuyo avatar_evo_id apunta al evo de
-- OTRO avatar, lo redirigimos al evo del avatar correcto en el mismo
-- nivel. Tras el paso 2 ya existen todos los niveles, así que se
-- arregla en una sola pasada.
-- ─────────────────────────────────────────────────────────────────────

UPDATE public.user_avatar ua
SET avatar_evo_id = correct_ae.id
FROM
  public.avatar_evo wrong_ae,
  public.avatar_evo correct_ae
WHERE
  ua.avatar_evo_id      = wrong_ae.id
  AND wrong_ae.avatar_id != ua.avatar_id      -- el evo apunta a otro avatar
  AND correct_ae.avatar_id = ua.avatar_id     -- evo correcto para este avatar
  AND correct_ae.level     = wrong_ae.level;  -- mismo nivel


-- ─────────────────────────────────────────────────────────────────────
-- PASO 5: VERIFICACIÓN
-- Tras esto NO debe quedar ninguna fila con estado != 'OK'.
-- ─────────────────────────────────────────────────────────────────────

SELECT
  ua.user_id,
  a.avatar_name,
  ua.current,
  ua.current_xp,
  ae.level,
  ae.evo_img,
  CASE WHEN ae.avatar_id = ua.avatar_id THEN 'OK'
       ELSE 'INCORRECTO' END AS estado
FROM public.user_avatar ua
JOIN public.avatars    a  ON a.avatar_id = ua.avatar_id
JOIN public.avatar_evo ae ON ae.id       = ua.avatar_evo_id
ORDER BY ua.user_id, ua.current DESC;
