-- =============================================
-- MOMENTUM APP - Cambiar avatar por defecto a Gymbro
--
-- El trigger handle_new_user buscaba el avatar 'Stickman' (que ya no
-- existe en la BBDD), por lo que los usuarios nuevos no recibían
-- ninguna fila en user_avatar y la app no encontraba avatar activo.
--
-- Esta migration:
--   1) Reescribe handle_new_user para asignar 'Gymbro' como avatar
--      por defecto y marcar la fila con current = true.
--   2) Repara los usuarios ya creados que se hayan quedado sin avatar.
--
-- Ejecutar en: Supabase > SQL Editor. Es idempotente.
-- =============================================

-- ─────────────────────────────────────────────────────────────────────
-- PASO 1: Reescribir el trigger
-- ─────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_avatar_id int8;
  v_evo_id    int8;
BEGIN
  -- Crear perfil de usuario
  INSERT INTO public."user" (id, username, coins, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text FROM 1 FOR 6)),
    0,
    now(),
    now()
  );

  -- Buscar avatar Gymbro nivel 1
  SELECT a.avatar_id INTO v_avatar_id
  FROM public.avatars a
  WHERE a.avatar_name = 'Gymbro'
  LIMIT 1;

  SELECT e.id INTO v_evo_id
  FROM public.avatar_evo e
  WHERE e.avatar_id = v_avatar_id AND e.level = 1
  LIMIT 1;

  -- Asignar avatar por defecto, equipado (current = true)
  IF v_avatar_id IS NOT NULL AND v_evo_id IS NOT NULL THEN
    INSERT INTO public.user_avatar (user_id, avatar_id, avatar_evo_id, current_xp, current)
    VALUES (NEW.id, v_avatar_id::int4, v_evo_id, 0, true);
  END IF;

  RETURN NEW;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────
-- PASO 2: Reparar usuarios ya creados que se quedaron sin avatar
-- (porque el trigger anterior fallaba al no encontrar 'Stickman').
-- ─────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gymbro_id  int8;
  v_evo_lvl1_id int8;
BEGIN
  SELECT a.avatar_id INTO v_gymbro_id
  FROM public.avatars a
  WHERE a.avatar_name = 'Gymbro'
  LIMIT 1;

  SELECT e.id INTO v_evo_lvl1_id
  FROM public.avatar_evo e
  WHERE e.avatar_id = v_gymbro_id AND e.level = 1
  LIMIT 1;

  IF v_gymbro_id IS NULL OR v_evo_lvl1_id IS NULL THEN
    RAISE NOTICE 'Gymbro o su evo lvl1 no existe — abortando reparación.';
    RETURN;
  END IF;

  -- Insertar Gymbro lvl1 equipado para usuarios sin ningún user_avatar
  INSERT INTO public.user_avatar (user_id, avatar_id, avatar_evo_id, current_xp, current)
  SELECT u.id, v_gymbro_id::int4, v_evo_lvl1_id, 0, true
  FROM public."user" u
  WHERE NOT EXISTS (
    SELECT 1 FROM public.user_avatar ua WHERE ua.user_id = u.id
  );
END $$;


-- ─────────────────────────────────────────────────────────────────────
-- PASO 3: Verificación
-- Debe devolver 0 filas: cada usuario tiene al menos un avatar activo.
-- ─────────────────────────────────────────────────────────────────────

SELECT u.id, u.username
FROM public."user" u
WHERE NOT EXISTS (
  SELECT 1 FROM public.user_avatar ua
  WHERE ua.user_id = u.id AND ua.current = true
);
