# Auditoría de Seguridad — Momentum App

> **Fecha:** 27 abril 2026
> **Branch:** main
> **Alcance:** Flutter app + Supabase backend (PostgreSQL + Auth + RLS)
> **Auditor:** Revisión automatizada del código

---

## Resumen Ejecutivo

Se han revisado **18 archivos Dart**, **3 migraciones SQL**, configuración de secretos y dependencias. El proyecto sigue buenas prácticas en autenticación (Supabase Auth + JWT), validación de formularios y aislamiento por feature. Sin embargo, se han detectado **3 vulnerabilidades críticas** relacionadas con RLS faltante en tablas del catálogo y el shipping del fichero `.env` en builds web.

| Severidad | Hallazgos |
|-----------|-----------|
| 🔴 **Crítica** | 3 |
| 🟠 **Alta** | 4 |
| 🟡 **Media** | 5 |
| 🔵 **Baja / Informativa** | 6 |

---

## 🔴 CRÍTICAS

### C1. Tablas sin RLS — escritura/lectura libre con la anon key

**Archivos:** [supabase/migrations/](../supabase/migrations/), [lib/core/constants/app_constants.dart](../lib/core/constants/app_constants.dart)

Las migraciones existentes (`001`, `002`, `003`) solo activan RLS sobre `user`, `habit`, `user_habit` y `user_avatar`. El resto de tablas declaradas en `AppConstants` **no tienen RLS activado**, por lo que cualquier persona con la `SUPABASE_ANON_KEY` (que viaja en el bundle del cliente) puede leer, modificar o borrar:

- `achievement` — catálogo de logros
- `user_achievement` — logros conseguidos por usuario
- `statistic` — catálogo de estadísticas
- `user_statistic` — estadísticas de cada usuario
- `avatars` — catálogo de avatares
- `avatar_evo` — evoluciones de avatares

**Impacto:** un atacante puede regalarse logros, estadísticas falseadas, avatares o vaciar/alterar los catálogos. Las migraciones que vienen recomiendan ejecutar el siguiente SQL:

```sql
-- Catálogos: lectura pública para autenticados, escritura solo desde el panel
ALTER TABLE public.achievement ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.statistic   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avatars     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avatar_evo  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "catalog read" ON public.achievement FOR SELECT TO authenticated USING (true);
CREATE POLICY "catalog read" ON public.statistic   FOR SELECT TO authenticated USING (true);
CREATE POLICY "catalog read" ON public.avatars     FOR SELECT TO authenticated USING (true);
CREATE POLICY "catalog read" ON public.avatar_evo  FOR SELECT TO authenticated USING (true);
-- (No se crean políticas INSERT/UPDATE/DELETE → solo el rol service_role puede escribir)

-- Tablas de relación usuario↔catálogo: cada usuario solo ve/modifica las suyas
ALTER TABLE public.user_achievement ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_statistic   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "own select" ON public.user_achievement FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "own insert" ON public.user_achievement FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "own update" ON public.user_achievement FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "own delete" ON public.user_achievement FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "own select" ON public.user_statistic FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "own insert" ON public.user_statistic FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "own update" ON public.user_statistic FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "own delete" ON public.user_statistic FOR DELETE USING (auth.uid() = user_id);
```

---

### C2. `habit` permite INSERT sin restricción (`with check (true)`)

**Archivo:** [supabase/migrations/002_habits.sql](../supabase/migrations/002_habits.sql) (línea 21)

```sql
create policy "Habit insercion propia"
  on public.habit for insert
  to authenticated
  with check (true);   -- ⚠️ ningún filtro
```

**Impacto:** cualquier usuario autenticado puede insertar filas arbitrarias en `habit` sin necesidad de hacer también el `user_habit` correspondiente, generando hábitos huérfanos que no son visibles para nadie pero que ocupan espacio y rompen integridad.

**Mitigación:** dado que el modelo de propiedad se basa en la junction `user_habit`, este `WITH CHECK (true)` es necesario por orden de inserción (el habit_id se necesita antes de poder vincularlo). Recomendaciones:

1. Mover ambos INSERT a una **función SQL `create_habit(name, descript, time)`** marcada `SECURITY DEFINER` que haga las dos operaciones en transacción y devuelva el `habit_id`.
2. Restringir el `INSERT` directo en `habit` (`WITH CHECK (false)`) y forzar el uso de la función.

---

### C3. `habit` permite SELECT a cualquier usuario autenticado

**Archivo:** [supabase/migrations/002_habits.sql](../supabase/migrations/002_habits.sql) (línea 16)

```sql
create policy "Habit lectura autenticados"
  on public.habit for select
  to authenticated
  using (true);
```

**Impacto:** un usuario A puede consultar directamente la tabla `habit` (vía PostgREST con su anon key) y leer hábitos de cualquier otro usuario si conoce o adivina el `habit_id` (es secuencial, fácil de iterar). El JOIN actual `user_habit → habit` filtra por `user_id`, pero la tabla `habit` es accesible directamente. Esto **expone los nombres y descripciones de hábitos privados** de todos los usuarios.

**Mitigación:**

```sql
DROP POLICY "Habit lectura autenticados" ON public.habit;

CREATE POLICY "Habit lectura propia" ON public.habit FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_habit
      WHERE user_habit.habit_id = habit.habit_id
        AND user_habit.user_id  = auth.uid()
    )
  );
```

El JOIN seguirá funcionando porque PostgREST aplica RLS sobre `habit` después de la unión, y la subconsulta de `user_habit` usa `auth.uid()`.

---

## 🟠 ALTAS

### A1. `.env` empaquetado como asset (Flutter Web expone credenciales)

**Archivo:** [pubspec.yaml](../pubspec.yaml) (línea 51-54)

```yaml
flutter:
  assets:
    - .env          # ⚠️ servido como asset estático en Flutter Web
    - assets/images/
    - assets/avatars/
```

En **Flutter Web**, los assets se sirven desde `<base_url>/assets/`. El fichero `.env` con `SUPABASE_URL` y `SUPABASE_ANON_KEY` queda accesible vía:

```
https://tu-app.com/assets/.env
```

**Impacto:** la `ANON_KEY` está **diseñada por Supabase para ser pública** (la seguridad real recae en RLS), pero exponerla así combinada con C1 amplifica el riesgo. Cualquier scraper puede recolectar la URL del proyecto y la key.

**Mitigación:**
- Para mobile: el `.env` empaquetado es la práctica habitual de `flutter_dotenv`, no es un problema.
- Para web: usar `--dart-define=SUPABASE_URL=...` en lugar de `.env`, o un `index.html` que inyecte las vars en `window` con valores específicos del entorno.
- En cualquier caso, **nunca poner la `service_role` key** aquí (no se ha detectado, comprobar).

---

### A2. Enumeración de cuentas en el formulario de registro

**Archivo:** [lib/features/auth/domain/auth_notifier.dart](../lib/features/auth/domain/auth_notifier.dart) (línea 84-86)

```dart
if (msg.contains('email already registered')) {
  return 'Este email ya está registrado.';
}
```

**Impacto:** un atacante puede enumerar emails registrados intentando registrarse y observando el mensaje. Combinado con un leak de emails (breach), permite confirmar qué usuarios tienen cuenta.

**Mitigación:** unificar el mensaje con uno genérico tipo `'Si el email es válido recibirás un correo de confirmación'` y dejar que Supabase Auth gestione el flujo silenciosamente. Activar **"Confirm email"** en Supabase Dashboard si no está ya.

---

### A3. `debugPrint` filtra mensajes de error con detalles del backend

**Archivo:** [lib/features/auth/domain/auth_notifier.dart](../lib/features/auth/domain/auth_notifier.dart) (líneas 41, 45, 66, 70)

```dart
debugPrint('[Auth] signIn AuthException: ${e.message}');
debugPrint('[Auth] signIn error: $e');
```

**Impacto:** en builds de debug/profile, el contenido de excepciones (incluido stack y posible info de la BD) se imprime en consola del navegador / logcat. En producción, `debugPrint` se elimina, pero conviene asegurarse de que no se incluyen datos sensibles.

**Mitigación:** ya está mitigado parcialmente porque Flutter elimina `debugPrint` en release. Aun así, evitar imprimir el `${e}` completo (que incluye stack) y limitarse a `e.message`.

---

### A4. Trigger `SECURITY DEFINER` lee `raw_user_meta_data` controlado por el cliente

**Archivo:** [supabase/migrations/001_auth_profiles.sql](../supabase/migrations/001_auth_profiles.sql) (línea 47)

```sql
COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || ...)
```

El campo `raw_user_meta_data` es **escribible por el cliente** durante el `signUp` (`data: {'username': ...}`). El trigger lo guarda directamente en `public."user".username`.

**Impacto:** un usuario puede registrarse con cualquier `username` sin pasar por el regex `^[a-zA-Z0-9_]+$` que aplica el formulario Flutter (puede llamar al endpoint de Supabase Auth directamente con un curl). Podría poner caracteres unicode raros, scripts, espacios, etc.

**Mitigación:** validar el username dentro del trigger:

```sql
DECLARE
  v_username text;
BEGIN
  v_username := NEW.raw_user_meta_data->>'username';
  IF v_username IS NULL OR v_username !~ '^[a-zA-Z0-9_]{3,10}$' THEN
    v_username := 'user_' || substring(NEW.id::text FROM 1 FOR 6);
  END IF;
  ...
```

---

## 🟡 MEDIAS

### M1. Sesión JWT en `localStorage` (Flutter Web vulnerable a XSS)

`supabase_flutter` en web guarda la sesión en `localStorage`. Si en el futuro se introduce algún `Html.unsafe()`, `WebView` o markdown sin sanitizar, una XSS robaría el JWT.

**Mitigación:** mantener todo el render dentro del framework Flutter (no inyectar HTML), evitar `dart:html` con contenido de usuario, y considerar usar `flutter_secure_storage` con backend `cookies` cuando esté disponible.

---

### M2. Falta validación server-side de longitud de password

**Archivos:** [lib/core/constants/app_constants.dart](../lib/core/constants/app_constants.dart) (`passwordMinLength = 8`), Supabase Dashboard

El cliente Flutter exige 8 caracteres, pero Supabase Auth por defecto acepta passwords de **6 caracteres**. Un atacante que use el endpoint de Supabase directamente puede crear cuentas con passwords cortas.

**Mitigación:** ir a Supabase Dashboard → Authentication → Settings → Password → cambiar mínimo a 8 (o el que se quiera).

---

### M3. Sin rate-limiting a nivel de app

Aunque Supabase Auth tiene límites globales, el formulario de login/registro no implementa throttling local (ej. esperar 1s tras 3 intentos fallidos). Un usuario impaciente puede martillear el botón.

**Mitigación:** añadir un debounce o desactivar el botón durante N segundos después de un fallo. No es crítico pero es UX + protección extra.

---

### M4. La descripción del hábito no se valida

**Archivo:** [lib/features/habits/presentation/habit_form_screen.dart](../lib/features/habits/presentation/habit_form_screen.dart)

```dart
TextFormField(
  controller: _descController,
  maxLength: 100,        // solo límite UI
  // sin validator
)
```

**Impacto:** se puede enviar una descripción con caracteres unicode raros, emoji bombs, o scripts (que no se ejecutan en Flutter pero sí podrían si alguien renderiza el dato en una web fuera de la app).

**Mitigación:** añadir un `validator` que limite caracteres permitidos o use `Bidi.stripHtmlIfNeeded()` u otras sanitizaciones simples.

---

### M5. `user_avatar.avatar_id` es `int4` y se castea desde `int8`

**Archivos:** [supabase/migrations/003_default_avatar.sql](../supabase/migrations/003_default_avatar.sql)

El esquema tiene una incoherencia: `avatars.avatar_id` es `int8` pero `user_avatar.avatar_id` es `int4`. El trigger usa `v_avatar_id::int4`. Si en el futuro se generan más de 2^31 avatares, los IDs no caben — improbable, pero refleja que el esquema no está bien tipado.

**Mitigación:** unificar a `int8` con `ALTER TABLE public.user_avatar ALTER COLUMN avatar_id TYPE int8;`.

---

## 🔵 BAJAS / INFORMATIVAS

### I1. `SUPABASE_URL` en `.env.example` versionado

[.env.example](../.env.example) contiene la URL real del proyecto (`https://wkkdtdeumzmvkpobgrtr.supabase.co`). Las URLs de Supabase **no son secretos**, pero por convención se sustituyen por `TU_URL_AQUI`.

### I2. Mensaje de error genérico de login (✅ correcto)

`'Email o contraseña incorrectos.'` no permite enumeración. Bien.

### I3. Username regex restrictivo (✅ correcto)

`^[a-zA-Z0-9_]+$` rechaza inyecciones por display-name. Bien.

### I4. Habit name `maxLength` enforced (✅ correcto)

`AppConstants.habitNameMaxLength = 50` aplicado tanto por `maxLength` del `TextFormField` como por `validator`.

### I5. Sin dependencias con CVEs conocidos

Versiones revisadas:
- `supabase_flutter: ^2.8.4` — actual a fecha de hoy
- `go_router: ^14.6.2` — actual
- `flutter_riverpod: ^2.6.1` — actual

No hay alertas en `pub.dev` para estas versiones.

### I6. `.env` correctamente gitignored

[.gitignore](../.gitignore) tiene `.env` como entrada explícita. `git ls-files .env` no lo encuentra trackeado. ✅

---

## Recomendaciones Priorizadas

| # | Acción | Esfuerzo | Impacto |
|---|--------|----------|---------|
| 1 | Aplicar RLS a las tablas faltantes (C1) | 30 min | 🔴 Crítico |
| 2 | Restringir `SELECT` en `habit` por propietario (C3) | 10 min | 🔴 Crítico |
| 3 | Función `create_habit` `SECURITY DEFINER` (C2) | 1h | 🔴 Crítico |
| 4 | Cambiar a `--dart-define` en build web (A1) | 1h | 🟠 Alto |
| 5 | Validar username en el trigger (A4) | 15 min | 🟠 Alto |
| 6 | Subir password min a 8 en Supabase (M2) | 1 min | 🟡 Medio |
| 7 | Mensaje genérico en registro (A2) | 5 min | 🟠 Alto |

---

## Apéndice: Cobertura

**Archivos analizados:**
- `lib/main.dart`, `lib/core/router/app_router.dart`, `lib/core/constants/app_constants.dart`
- `lib/features/auth/{data,domain,presentation}/*.dart`
- `lib/features/habits/{data,domain,presentation}/*.dart`
- `lib/features/profile/{data,presentation}/*.dart`
- `supabase/migrations/00{1,2,3}_*.sql`
- `pubspec.yaml`, `.gitignore`, `.env`, `.env.example`

**Vectores no cubiertos** (fuera del alcance de esta auditoría automatizada):
- Configuración de buckets de Supabase Storage (no se usan en este proyecto)
- Claves OAuth de proveedores externos (no aplicable)
- Configuración CORS del proyecto Supabase (revisar manualmente en dashboard)
- Auditoría dinámica con burp/OWASP ZAP

---

*Auditoría generada el 2026-04-27. Revisar trimestralmente o tras cambios mayores en el modelo de datos.*
