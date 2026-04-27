-- =============================================
-- MOMENTUM APP - Avatar Stickman por defecto
-- Ejecutar en: Supabase > SQL Editor
-- =============================================

-- 1. Insertar avatar Stickman (precio 0 = gratis / por defecto)
DO $$
DECLARE
  v_avatar_id int8;
  v_evo_id    int8;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.avatars WHERE avatar_name = 'Stickman') THEN
    INSERT INTO public.avatars (avatar_name, avatar_descript, avatar_price)
    VALUES ('Stickman', 'Tu compañero desde el primer día. Simple pero fiel.', 0)
    RETURNING avatar_id INTO v_avatar_id;

    INSERT INTO public.avatar_evo (avatar_id, level, evo_img)
    VALUES (v_avatar_id, 1, 'stickman_lv1')
    RETURNING id INTO v_evo_id;
  END IF;
END $$;

-- 2. RLS para user_avatar
ALTER TABLE public.user_avatar ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_avatar select own"  ON public.user_avatar;
DROP POLICY IF EXISTS "user_avatar insert own"  ON public.user_avatar;
DROP POLICY IF EXISTS "user_avatar update own"  ON public.user_avatar;
DROP POLICY IF EXISTS "user_avatar delete own"  ON public.user_avatar;

CREATE POLICY "user_avatar select own" ON public.user_avatar
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_avatar insert own" ON public.user_avatar
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_avatar update own" ON public.user_avatar
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "user_avatar delete own" ON public.user_avatar
  FOR DELETE USING (auth.uid() = user_id);

-- 3. Actualizar trigger para asignar Stickman al registrarse
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

  -- Buscar avatar Stickman nivel 1
  SELECT a.avatar_id INTO v_avatar_id
  FROM public.avatars a
  WHERE a.avatar_name = 'Stickman'
  LIMIT 1;

  SELECT e.id INTO v_evo_id
  FROM public.avatar_evo e
  WHERE e.avatar_id = v_avatar_id AND e.level = 1
  LIMIT 1;

  -- Asignar avatar por defecto
  IF v_avatar_id IS NOT NULL AND v_evo_id IS NOT NULL THEN
    INSERT INTO public.user_avatar (user_id, avatar_id, avatar_evo_id)
    VALUES (NEW.id, v_avatar_id::int4, v_evo_id);
  END IF;

  RETURN NEW;
END;
$$;

-- =============================================
-- VERIFICACIÓN:
-- SELECT * FROM public.avatars;      -> debe haber un 'Stickman'
-- SELECT * FROM public.avatar_evo;   -> debe haber level 1 del Stickman
-- =============================================
