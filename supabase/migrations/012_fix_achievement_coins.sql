-- =============================================
-- MOMENTUM APP - Fix: las monedas de los logros nunca se otorgaban
--
-- Causa: tanto check_and_grant_achievements como claim_achievement
-- insertaban la fila en user_achievement pero NUNCA hacían
-- UPDATE user SET coins = coins + achievement_coins. El saldo se
-- quedaba igual aunque el logro apareciera como desbloqueado.
--
-- Diseño deseado (confirmado): las monedas llegan automáticamente al
-- desbloquearse el logro (vía check_and_grant_achievements). El botón
-- "Reclamar" sigue funcionando como camino defensivo por si en el
-- futuro hay logros que no se otorgan automáticamente.
--
-- Ejecutar en: Supabase > SQL Editor. Es idempotente.
-- =============================================


-- ─────────────────────────────────────────────────────────────────────
-- PASO 1: Columna de auditoría en user_achievement
-- Sirve para (a) saber si ya se le pagaron las coins de una fila,
-- (b) hacer el retroactivo de PASO 4 de forma idempotente.
-- Filas pre-existentes quedan en FALSE → se cobrarán en el retroactivo.
-- ─────────────────────────────────────────────────────────────────────

ALTER TABLE public.user_achievement
  ADD COLUMN IF NOT EXISTS coins_granted boolean NOT NULL DEFAULT false;


-- ─────────────────────────────────────────────────────────────────────
-- PASO 2: check_and_grant_achievements
-- Reescrita para que, además de insertar el logro, sume sus coins al
-- saldo del usuario y marque coins_granted = true.
--
-- DROP previo: PostgreSQL no permite cambiar el tipo de retorno con
-- CREATE OR REPLACE si la firma de las columnas devueltas difiere.
-- ─────────────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.check_and_grant_achievements(uuid);

CREATE OR REPLACE FUNCTION public.check_and_grant_achievements(p_user_id uuid)
RETURNS TABLE (new_id bigint, new_name text, new_coins bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total      bigint;
  v_max_repeat bigint;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM habit_completion WHERE user_id = p_user_id;

  SELECT COALESCE(MAX(cnt), 0) INTO v_max_repeat
  FROM (
    SELECT COUNT(*) AS cnt FROM habit_completion
    WHERE user_id = p_user_id GROUP BY habit_name
  ) t;

  RETURN QUERY
  WITH earned AS (
    SELECT a.id, a.achievement_name, a.achievement_coins
    FROM achievement a
    WHERE NOT EXISTS (
      SELECT 1 FROM user_achievement ua
      WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id
    ) AND (
      (a.criteria_type = 'total_completions' AND v_total >= a.criteria_value)
      OR
      (a.criteria_type = 'same_habit' AND v_max_repeat >= a.criteria_value)
      OR
      (a.criteria_type = 'time_of_day'
        AND a.criteria_hour_start IS NOT NULL
        AND a.criteria_hour_end   IS NOT NULL
        AND (
          SELECT COALESCE(MAX(streak_len), 0)
          FROM (
            SELECT COUNT(*) AS streak_len
            FROM (
              SELECT d, d - CAST(ROW_NUMBER() OVER (ORDER BY d) AS int) AS grp
              FROM (
                SELECT DISTINCT DATE(completed_at AT TIME ZONE 'UTC') AS d
                FROM habit_completion
                WHERE user_id = p_user_id
                  AND EXTRACT(HOUR FROM completed_at AT TIME ZONE 'UTC') >= a.criteria_hour_start
                  AND EXTRACT(HOUR FROM completed_at AT TIME ZONE 'UTC') < a.criteria_hour_end
              ) distinct_days
            ) islands
            GROUP BY grp
          ) streaks
        ) >= a.criteria_value
      )
    )
  ),
  inserted AS (
    INSERT INTO user_achievement (user_id, achievement_id, coins_granted)
    SELECT p_user_id, earned.id, true FROM earned
    RETURNING achievement_id
  ),
  -- FIX: sumar al saldo de monedas el total de coins de los logros recién desbloqueados
  coins_added AS (
    UPDATE public."user" u
    SET coins      = u.coins + COALESCE((SELECT SUM(achievement_coins) FROM earned), 0),
        updated_at = now()
    WHERE u.id = p_user_id
      AND EXISTS (SELECT 1 FROM earned)
    RETURNING u.id
  )
  SELECT e.id, e.achievement_name, e.achievement_coins
  FROM earned e
  WHERE EXISTS (SELECT 1 FROM inserted i WHERE i.achievement_id = e.id)
    -- referencia inocua a coins_added para asegurar que la CTE se evalúa
    AND (SELECT COUNT(*) FROM coins_added) >= 0;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────
-- PASO 3: claim_achievement
-- Reescrita para sumar las monedas tras insertar. Útil como camino
-- defensivo: si una fila quedara con coins_granted = false (caso raro),
-- al reclamar manualmente se le pagan las coins y se marca como pagada.
--
-- DROP previo por si la firma anterior difería (p.ej. int vs bigint).
-- ─────────────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.claim_achievement(uuid, bigint);
DROP FUNCTION IF EXISTS public.claim_achievement(uuid, integer);
DROP FUNCTION IF EXISTS public.claim_achievement(uuid, int);

CREATE OR REPLACE FUNCTION public.claim_achievement(
  p_user_id        uuid,
  p_achievement_id bigint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_coins   bigint;
  v_exists  boolean;
  v_granted boolean;
BEGIN
  SELECT
    EXISTS (
      SELECT 1 FROM user_achievement
      WHERE user_id = p_user_id AND achievement_id = p_achievement_id
    ),
    COALESCE((
      SELECT coins_granted FROM user_achievement
      WHERE user_id = p_user_id AND achievement_id = p_achievement_id
    ), false)
  INTO v_exists, v_granted;

  SELECT achievement_coins INTO v_coins
  FROM achievement WHERE id = p_achievement_id;

  IF NOT v_exists THEN
    -- Aún no estaba desbloqueado: insertar y otorgar coins
    INSERT INTO user_achievement (user_id, achievement_id, coins_granted)
    VALUES (p_user_id, p_achievement_id, true);

    UPDATE public."user"
    SET coins      = coins + COALESCE(v_coins, 0),
        updated_at = now()
    WHERE id = p_user_id;

  ELSIF NOT v_granted THEN
    -- Estaba desbloqueado pero sin pagar (caso retroactivo o bug pasado):
    -- otorgar coins y marcar como pagada
    UPDATE public."user"
    SET coins      = coins + COALESCE(v_coins, 0),
        updated_at = now()
    WHERE id = p_user_id;

    UPDATE user_achievement
    SET coins_granted = true
    WHERE user_id = p_user_id AND achievement_id = p_achievement_id;
  END IF;
  -- Si v_exists AND v_granted → idempotente, nada que hacer.
END;
$$;


-- ─────────────────────────────────────────────────────────────────────
-- PASO 4: Retroactivo
-- Sumar al saldo de cada usuario las monedas de los logros que tiene
-- desbloqueados pero que nunca cobró (coins_granted = false).
-- Una sola vez por fila: tras esto se marca coins_granted = true.
-- ─────────────────────────────────────────────────────────────────────

WITH pending AS (
  SELECT ua.user_id, COALESCE(SUM(a.achievement_coins), 0) AS total_due
  FROM public.user_achievement ua
  JOIN public.achievement      a ON a.id = ua.achievement_id
  WHERE ua.coins_granted = false
  GROUP BY ua.user_id
)
UPDATE public."user" u
SET coins      = u.coins + pending.total_due,
    updated_at = now()
FROM pending
WHERE u.id = pending.user_id;

UPDATE public.user_achievement
SET coins_granted = true
WHERE coins_granted = false;


-- ─────────────────────────────────────────────────────────────────────
-- PASO 5: Verificación
-- 5a: deben aparecer las coins esperadas por usuario
-- 5b: no debe quedar ninguna fila con coins_granted = false
-- ─────────────────────────────────────────────────────────────────────

SELECT u.id, u.username, u.coins,
       COALESCE(SUM(a.achievement_coins), 0) AS coins_de_logros
FROM public."user" u
LEFT JOIN public.user_achievement ua ON ua.user_id = u.id
LEFT JOIN public.achievement       a ON a.id = ua.achievement_id
GROUP BY u.id, u.username, u.coins
ORDER BY u.username;

SELECT COUNT(*) AS filas_sin_pagar
FROM public.user_achievement
WHERE coins_granted = false;
