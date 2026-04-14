# FASE 4: Implementació — Momentum App

> **Mòdul 0492: Projecte Intermodular**
> **Equip:** Momentum | **Repositori:** [dateni24-dot/Momentum](https://github.com/dateni24-dot/Momentum)

---

## Índex

1. [Introducció a la Fase 4](#1-introducció-a-la-fase-4)
2. [Matriu de Traçabilitat](#2-matriu-de-traçabilitat)
3. [Estructura de Sprints a Jira](#3-estructura-de-sprints-a-jira)
4. [Creació de la Base de Dades](#4-creació-de-la-base-de-dades)
5. [Desenvolupament — Sprint 1](#5-desenvolupament--sprint-1)
6. [Proves — Sprint 1](#6-proves--sprint-1)
7. [Desenvolupament — Sprint 2](#7-desenvolupament--sprint-2)
8. [Proves — Sprint 2](#8-proves--sprint-2)
9. [Control de Versions i Seguiment](#9-control-de-versions-i-seguiment)

---

## 1. Introducció a la Fase 4

La quarta fase del projecte, l'anomenada **Implementació**, consisteix a realitzar els processos i estructures que s'han definit per al sistema a les fases anteriors. L'objectiu és desenvolupar una aplicació completament funcional en dues plataformes, a partir de la documentació prèvia (requeriments, anàlisi i disseny).

Els **Resultats d'Aprenentatge (RA)** establerts per a la pràctica són:

- **RA3.** Planifica l'execució del projecte, determinant el pla d'intervenció i la documentació associada.
- **RA4.** Defineix els procediments per al seguiment i el control en l'execució del projecte, justificant la selecció de variables i instruments emprats.

El desenvolupament s'organitza en **6 Sprints setmanals de 16 hores cadascun**:

| Sprint | Dates | Pes avaluació |
|--------|-------|--------------|
| Sprint 1 | 7 – 14 abril 2026 | 5% |
| Sprint 2 | 15 – 22 abril 2026 | 10% |
| Sprint 3 | 23 – 29 abril 2026 | 15% |
| Sprint 4 | 30 abril – 6 maig 2026 | 20% |
| Sprint 5 | 7 – 13 maig 2026 | 25% |
| Sprint 6 | 14 – 20 maig 2026 | 25% |

---

## 2. Matriu de Traçabilitat

| Requisit | Disseny | Implementació | Prova |
|----------|---------|---------------|-------|
| Registre d'usuari | Formulari de creació d'usuari (username i contrasenya), pujada de dades a la BD | `userRegister()` | Registrar un usuari i verificar que les dades es pugen correctament a la BD |
| Inici de sessió | Formulari de login (email i contrasenya) amb gestió d'errors | `userLogin()` | Iniciar sessió amb usuari de prova; provar amb credencials incorrectes |
| Creació d'hàbit | Formulari amb nom, descripció i durada; inserció a `habit` i `user_habit` | `createHabit()` | Crear un hàbit de prova i verificar que apareix a la llista |
| Edició d'hàbit | Formulari pre-emplenat amb les dades de l'hàbit existent | `updateHabit()` | Modificar nom i durada d'un hàbit i comprovar que els canvis es persisteixen |
| Eliminació d'hàbit | Diàleg de confirmació; eliminació de `user_habit` i `habit` | `deleteHabit()` | Eliminar un hàbit i comprovar que desapareix de la llista |
| Canvi de nom d'usuari | Popup de canvi de nom d'usuari | `changeUsername()` | Canviar el nom d'usuari en l'apartat d'ajustos |
| Canvi de contrasenya | Popup que demana la contrasenya original i la nova | `changePassword()` | Canviar la contrasenya respectant els requisits mínims |
| Eliminar dades d'usuari | Botó amb confirmació prèvia | `deleteData()` | Verificar que s'eliminen totes les dades de l'usuari |
| Sistema de nivells i XP | Imatge d'avatar + barra de progrés | `levelUp()` | Comprovar que en arribar al límit d'XP es puja de nivell |
| Sistema de logres | Targetes de logres (gris → verd) amb botó de recompensa | `completeAchievement()` | Verificar notificació i reclamació de monedes |
| Tienda d'avatars | Targetes amb avatars i preus | `avatarPurchase()` | Comprovar que no es pot comprar sense monedes suficients |
| Estadístiques | Llistat d'estadístiques del perfil | Classe `Stats` | Verificar que les dades corresponen amb el perfil de prova |
| Sistema d'amics | Cercador, afegir i eliminar amics | `searchForFriends()`, `addFriend()`, `deleteFriend()` | Provar el cercador per text parcial i complet |
| Tauler de publicació | Publicar hàbit/logre amb comentari | `publish()`, `buff()` | Compartir un hàbit completat i donar "buff" a una publicació |

---

## 3. Estructura de Sprints a Jira

### Sprint 1 (7 – 14 abril 2026)

| ID | Tasca | Tipus | Estat |
|----|-------|-------|-------|
| MOM-91 | Configuració del projecte (BD, entorn, repositori) | Implementació | ✅ DONE |
| MOM-92 | Implementació de l'inici de sessió i registre | Implementació | ✅ DONE |
| MOM-95 | Estructura inicial de la base de dades | Implementació | ✅ DONE |
| MOM-T01 | Proves: Login, Register i seguretat | Proves | 🔄 IN PROGRESS |

📸 `[CAPTURA — Taulell Jira Sprint 1 amb les tasques i el seu estat]`

### Sprint 2 (15 – 22 abril 2026)

| ID | Tasca | Tipus | Estat |
|----|-------|-------|-------|
| SCRUM-15 | Creació, edició i eliminació d'hàbits | Implementació | ✅ DONE |
| SCRUM-16 | Validacions bàsiques dels hàbits | Implementació | 🔄 IN PROGRESS |
| SCRUM-17 | Persistència de dades (user_habit a Supabase) | Implementació | ✅ DONE |
| SCRUM-18 | Proves: CRUD d'hàbits | Proves | 🔄 IN PROGRESS |
| *(extra)* | Pantalla principal (HomeScreen) | Implementació | ✅ DONE |

📸 `[CAPTURA — Taulell Jira Sprint 2 amb les tasques i el seu estat]`

---

## 4. Creació de la Base de Dades

### 4.1 Tecnologia i configuració

El backend de l'aplicació s'ha creat amb **Supabase** (PostgreSQL), a la regió **West EU (París)**. El projecte es diu `MomentumBD`.

### 4.2 Estructura de taules

L'estructura de la BD parteix de la taula `user`. La resta de taules giren totes al voltant d'aquesta. Al ser totes interrelacions **molts a molts (many-to-many)**, s'han creat taules intermèdies per relacionar els valors dels usuaris amb la resta de taules i mantenir la integritat referencial.

```
user
 ├── user_habit       → habit
 ├── user_avatar      → avatars
 │                         └── avatar_evo  (one-to-many)
 ├── user_achievement → achievement
 └── user_statistic   → statistic
```

**Funcionament exemple:** quan un usuari registra un nou hàbit, el hàbit es registra a la taula `habit` i, a la vegada, a la taula `user_habit`, assegurant la integritat referencial.

### 4.3 Descripció de les taules

| Taula | Camps principals | Descripció |
|-------|-----------------|------------|
| `user` | `id` (uuid), `username`, `coins`, `created_at`, `updated_at` | Perfil de l'usuari, vinculat a `auth.users` |
| `habit` | `habit_id` (int8), `habit_name`, `habit_descript`, `time` (int2) | Definició d'un hàbit (durada en minuts) |
| `user_habit` | `user_id` (uuid), `habit_id` (int4) | Relació molts a molts usuari ↔ hàbit |
| `achievement` | `id` (int8), `achievement_name`, `achievement_description`, `achievement_coins` | Catàleg de logros |
| `user_achievement` | `user_id` (uuid), `achievement_id` (int4) | Relació usuari ↔ logro |
| `avatars` | `avatar_id` (int8), `avatar_name`, `avatar_descript`, `avatar_price` | Catàleg d'avatars |
| `avatar_evo` | `level` (int8), `avatar_id` (int8), `evo_img` (text) | Evolucions d'avatars (one-to-many) |
| `user_avatar` | `user_id` (uuid), `avatar_id` (int4) | Relació usuari ↔ avatar |
| `statistic` | `id` (int8), `stat_name`, `value_type` | Catàleg d'estadístiques |
| `user_statistic` | `user_id` (uuid), `statistic_id` (int4) | Relació usuari ↔ estadística |

📸 `[CAPTURA — Schema Visualizer de Supabase mostrant totes les taules i les seves relacions]`

### 4.4 Seguretat: Row Level Security (RLS)

Totes les taules tenen **RLS activat**. Les polítiques garanteixen que cada usuari només pot llegir i modificar les seves pròpies dades.

**Migració `001_auth_profiles.sql`** — RLS sobre la taula `user` + trigger `on_auth_user_created` per crear automàticament el perfil en registrar-se.

**Migració `002_habits.sql`** — RLS sobre les taules `habit` i `user_habit`:
- Qualsevol usuari autenticat pot llegir hàbits (necessari per al JOIN)
- Només pot actualitzar/eliminar si el hàbit li pertany (verificat via `user_habit`)
- `user_habit` restringida completament per `user_id`

---

## 5. Desenvolupament — Sprint 1

### 5.1 Configuració de l'entorn i repositori (MOM-91)

S'ha configurat l'entorn de desenvolupament complet:

- **IDE:** VS Code com a IDE principal per a Flutter/Dart
- **Emulació:** Android Studio per a proves en dispositiu virtual
- **Control de versions:** Repositori públic a GitHub (`dateni24-dot/Momentum`)
- **Backend:** Projecte creat a Supabase (`MomentumBD`) a la regió West EU (París)

**Stack tecnològic:**

| Tecnologia | Versió | Ús |
|------------|--------|-----|
| Flutter | 3.x | Framework multiplataforma |
| Dart | 3.x | Llenguatge de programació |
| Supabase Flutter | 2.x | Backend (BD + Auth) |
| Flutter Riverpod | 2.6.1 | Gestió d'estat (AsyncNotifier) |
| Go Router | 14.x | Navegació |
| Google Fonts (Inter) | 6.x | Tipografia |
| Flutter Dotenv | 5.x | Variables d'entorn |

**Estructura de carpetes (Clean Architecture):**

```
lib/
├── core/
│   ├── constants/    # AppConstants (noms de taules, validacions)
│   ├── router/       # app_router.dart (Go Router + guards auth)
│   └── theme/        # AppColors, AppTheme (Material 3 fosc)
└── features/
    ├── auth/
    │   ├── data/       # auth_provider.dart
    │   ├── domain/     # auth_notifier.dart
    │   └── presentation/
    │       ├── login_screen.dart
    │       ├── register_screen.dart
    │       └── widgets/
    └── habits/
        ├── data/       # habit_provider.dart (HabitRepository)
        ├── domain/     # habit_model.dart, habit_notifier.dart
        └── presentation/
            ├── home_screen.dart
            ├── habit_form_screen.dart
            └── widgets/
                └── habit_card.dart
```

📸 `[CAPTURA — Repositori GitHub amb l'estructura del projecte]`

### 5.2 Implementació del Login i Register (MOM-92 / MOM-95)

S'han implementat les pantalles d'inici de sessió i registre connectades a **Supabase Auth**.

**Disseny:** tema fosc `#0D0D0D`, verd corporatiu `#5DBE2A`, efectes neon, tipografia Inter (Google Fonts).

**Funcionalitats implementades:**

- Formulari de login amb camps email i contrasenya
- Formulari de registre amb creació de compte a Supabase Auth i inserció a la taula `user`
- Navegació automàtica al panell principal en cas d'autenticació correcta
- Missatge d'error en cas de credencials incorrectes o camp buit
- Botó "¿No tienes cuenta?" per canviar entre login i registre
- Validació d'email amb expressió regular
- Requisit mínim de 8 caràcters per a la contrasenya

**Mètodes implementats (`auth_notifier.dart`):**

```dart
// Autentica l'usuari via Supabase Auth
Future<AuthResult> signIn({required String email, required String password})

// Crea l'usuari a Auth i insereix el registre a la taula "user"
Future<AuthResult> signUp({required String email, required String password, required String username})

// Tanca la sessió de l'usuari actual
Future<void> signOut()
```

**Flux d'autenticació (Go Router):**

```
Sense sessió → /login o /register
Amb sessió   → /home (redirecció automàtica via refreshListenable)
```

📸 `[CAPTURA — Pantalla de Login de l'app]`

📸 `[CAPTURA — Pantalla de Register de l'app]`

📸 `[CAPTURA — Supabase Authentication mostrant un usuari de prova registrat]`

---

## 6. Proves — Sprint 1 (MOM-T01)

### 6.1 Proves de l'entorn i la BD

```gherkin
Feature: Configuració i estructura de la base de dades

  Scenario: El projecte compila sense errors
    Given l'entorn de desenvolupament està configurat
    When s'executa "flutter run" al projecte
    Then l'aplicació s'inicia sense errors de compilació en Android i Web

  Scenario: Les taules existeixen a Supabase
    Given el projecte Supabase "MomentumBD" està creat
    When s'accedeix al Table Editor de Supabase
    Then existeixen les taules: user, habit, achievement, statistic,
         avatars, avatar_evo, user_habit, user_avatar, user_achievement, user_statistic

  Scenario: La integritat referencial és correcta
    Given existeix un hàbit a la taula habit
    When s'intenta eliminar l'hàbit sense eliminar primer el registre a user_habit
    Then Supabase retorna un error de violació de clau forana (foreign key constraint)
```

📸 `[CAPTURA — Resultat de la prova de compilació (terminal sense errors)]`

📸 `[CAPTURA — Table Editor de Supabase mostrant totes les taules creades]`

### 6.2 Proves del Registre d'usuari

```gherkin
Feature: Registre d'un nou usuari

  Scenario: Registre amb dades vàlides
    Given l'usuari és a la pantalla de registre
    When introdueix un email vàlid i una contrasenya de mínim 8 caràcters
    And prem "Crear cuenta"
    Then es crea el compte a Supabase Auth
    And s'insereix un registre a la taula "user" amb el mateix UUID
    And l'usuari és redirigit al panell principal

  Scenario: Registre sense email
    Given l'usuari és a la pantalla de registre
    When deixa el camp email buit i prem "Crear cuenta"
    Then apareix un missatge d'error indicant que el correu és obligatori
    And no es crea cap compte

  Scenario: Registre amb email ja existent
    Given existeix un compte amb l'email "prova@test.com"
    When un altre usuari intenta registrar-se amb el mateix email
    Then Supabase retorna un error
    And l'app mostra "Este email ya está registrado."

  Scenario: Injecció SQL al camp email
    Given l'usuari és a la pantalla de registre
    When introdueix "' OR '1'='1" al camp email
    And prem "Crear cuenta"
    Then Supabase rebutja la petició
    And no s'accedeix a cap compte ni es compromet la base de dades
```

📸 `[CAPTURA — Prova de registre amb dades vàlides: usuari creat a Supabase Auth]`

📸 `[CAPTURA — Prova de registre i redirecció al home]`

📸 `[CAPTURA — Prova de registre sense email: missatge d'error a l'app]`

📸 `[CAPTURA — Prova de registre amb injecció SQL]`

### 6.3 Proves de l'Inici de sessió

```gherkin
Feature: Inici de sessió d'un usuari existent

  Scenario: Login amb credencials correctes
    Given existeix un usuari registrat amb email "prova@test.com"
    When introdueix l'email i la contrasenya correctes
    And prem "Iniciar sesión"
    Then l'app redirigeix al panell principal de l'usuari

  Scenario: Login amb contrasenya incorrecta
    Given existeix un usuari registrat
    When introdueix l'email correcte però una contrasenya errònia
    And prem "Iniciar sesión"
    Then apareix un missatge d'error genèric "Email o contraseña incorrectos."
    And l'usuari es manté a la pantalla de login

  Scenario: Login amb usuari inexistent
    Given no existeix cap compte amb l'email "fantasma@test.com"
    When l'usuari introdueix aquest email i qualsevol contrasenya
    And prem "Iniciar sesión"
    Then apareix un missatge d'error
    And no s'accedeix a cap compte

  Scenario: Login amb camps buits
    Given l'usuari és a la pantalla de login
    When prem "Iniciar sesión" sense omplir cap camp
    Then apareix un missatge de validació demanant que s'omplin els camps
```

📸 `[CAPTURA — Login correcte: redirecció al panell principal]`

📸 `[CAPTURA — Login amb contrasenya incorrecta: missatge d'error]`

📸 `[CAPTURA — Schema Visualizer de Supabase mostrant totes les taules i les seves relacions]`

---

## 7. Desenvolupament — Sprint 2

### 7.1 Pantalla principal — HomeScreen *(extra)*

Com a tasca addicional al Sprint 2, s'ha implementat la **pantalla principal de l'aplicació**, que substitueix el placeholder temporal que existia a la ruta `/home`.

**Disseny:** consistent amb Login/Register — fons fosc `#0D0D0D`, verd `#5DBE2A`, efectes neon en les targetes d'hàbits, tipografia Inter.

**Funcionalitats:**

- Capçalera amb logo petit de Momentum + salutació dinàmica (Buenos días / tardes / noches) + nom d'usuari llegit des dels metadades de Supabase Auth
- Línea divisora amb gradient verd
- Secció "Mis Hábitos" amb comptador de nombre d'hàbits actius
- Llista d'hàbits amb `HabitCard` (color determinista per `habit_id`, glow neon)
- Estat buit amb icona i text motivador quan no hi ha hàbits
- Botó FAB verd ("Nuevo hábito") amb efecte de glow
- Diàleg de confirmació per eliminar hàbits
- Botó de logout amb diàleg de confirmació
- Gestió d'errors de xarxa amb botó de reintent

**Arxius creats:**

| Arxiu | Descripció |
|-------|------------|
| `lib/features/habits/presentation/home_screen.dart` | Pantalla principal amb `CustomScrollView` i `SliverList` |
| `lib/features/habits/presentation/widgets/habit_card.dart` | Targeta d'hàbit amb barra de color i accions |

📸 `[CAPTURA — HomeScreen amb llista d'hàbits]`

📸 `[CAPTURA — HomeScreen en estat buit (sense hàbits)]`

---

### 7.2 Creació, edició i eliminació d'hàbits (SCRUM-15 / SCRUM-17)

S'ha implementat el **CRUD complet d'hàbits**, adaptat a l'esquema real de la base de dades.

#### Arquitectura (Clean Architecture)

```
habits/
├── domain/
│   ├── habit_model.dart      # Model + HabitColors + HabitDuration
│   └── habit_notifier.dart   # HabitsState, HabitResult (sealed), HabitsNotifier
└── data/
    └── habit_provider.dart   # HabitRepository + habitRepositoryProvider
```

#### Model de dades — `HabitModel`

Reflecteix l'esquema real de la taula `habit` de Supabase:

```dart
class HabitModel {
  final int habitId;       // habit_id (int8, auto-generat per Supabase)
  final String habitName;  // habit_name (varchar)
  final String? habitDescript; // habit_descript (text, opcional)
  final int time;          // time (int2) — durada en minuts
  final DateTime createdAt;
}
```

> **Nota de disseny:** el color de la targeta no s'emmagatzema a la BD. S'obté de forma determinista mitjançant `HabitColors.forHabit(habitId)`, que aplica `habitId % palette.length`. Això garanteix colors consistents sense modificar l'esquema.

#### Operacions CRUD — `HabitRepository`

La particularitat d'aquest repositori és que treballa amb **dues taules** per a cada operació, respectant la relació molts-a-molts de l'esquema:

```dart
// LLEGIR: JOIN user_habit → habit per a l'usuari actual
fetchHabits() → SELECT habit(*) FROM user_habit WHERE user_id = auth.uid()

// CREAR: inserció en dues fases
createHabit() → INSERT INTO habit(...) → INSERT INTO user_habit(user_id, habit_id)

// ACTUALITZAR: només la taula habit
updateHabit() → UPDATE habit SET ... WHERE habit_id = id

// ELIMINAR: neteja de les dues taules
deleteHabit() → DELETE FROM user_habit WHERE habit_id = id AND user_id = uid
             → DELETE FROM habit WHERE habit_id = id (si cap altre usuari el té)
```

#### Gestió d'estat — `HabitsNotifier`

Segueix el patró `AsyncNotifier` de Riverpod (igual que `AuthNotifier`):

```dart
// Resultat tipus sealed (pattern matching exhaustiu)
sealed class HabitResult {}
class HabitSuccess extends HabitResult {}
class HabitFailure extends HabitResult { final String message; }

// Proveïdor global
final habitsNotifierProvider =
    AsyncNotifierProvider<HabitsNotifier, HabitsState>(HabitsNotifier.new);
```

#### Pantalla de formulari — `HabitFormScreen`

Pantalla de creació i edició en un únic component, amb **preview en temps real** que s'actualitza mentre l'usuari escriu:

**Camps del formulari:**

| Camp | Validació | Correspon a BD |
|------|-----------|----------------|
| Nom | Obligatori, 2–50 caràcters | `habit_name` |
| Descripció | Opcional, màx. 100 caràcters | `habit_descript` |
| Durada | Selector de chips: 5, 10, 15, 20, 30, 45, 60, 90, 120 min | `time` |

**Mode edició vs. creació:**

```dart
// Detecció automàtica: si rep un HabitModel és edició, si no és creació
HabitFormScreen(habit: existingHabit)  // edició
HabitFormScreen()                       // creació
```

📸 `[CAPTURA — HabitFormScreen en mode creació]`

📸 `[CAPTURA — HabitFormScreen en mode edició amb preview actualitzat]`

📸 `[CAPTURA — HomeScreen amb hàbits creats mostrant colors i durades]`

#### Canvis a l'esquema de constants (`AppConstants`)

S'han corregit els noms de totes les taules per reflectir l'esquema real de Supabase (algunes constants tenien noms incorrectes amb "s" al final):

```dart
// Abans (incorrecte)       →  Ara (correcte)
tableHabits = 'habits'      →  tableHabits = 'habit'
tableAchievements = '...'   →  tableAchievements = 'achievement'
tableUserAvatars = '...'    →  tableUserAvatar = 'user_avatar'
// Nou afegit
tableUserHabits = 'user_habit'
```

#### Seguretat — Migració `002_habits.sql`

S'han afegit polítiques RLS a les taules `habit` i `user_habit` (les taules ja existien a Supabase):

```sql
-- habit: lectura oberta per a autenticats (necessari per al JOIN)
-- habit: update/delete restringit al propietari (via user_habit)
-- user_habit: totes les operacions restringides per user_id = auth.uid()
```

---

## 8. Proves — Sprint 2 (SCRUM-18)

### 8.1 Proves de creació d'hàbits

```gherkin
Feature: Creació d'un hàbit

  Scenario: Crear un hàbit amb dades vàlides
    Given l'usuari autenticat és a la pantalla principal
    When prem el botó "Nuevo hábito"
    And introdueix el nom "Llegir 30 minuts" i selecciona 30 min de durada
    And prem "Crear hábito"
    Then l'hàbit apareix a la llista de la pantalla principal
    And s'ha inserit un registre a la taula "habit" de Supabase
    And s'ha inserit un registre a la taula "user_habit" vinculant l'usuari

  Scenario: Crear un hàbit sense nom
    Given l'usuari és al formulari de creació d'hàbit
    When deixa el camp nom buit i prem "Crear hábito"
    Then apareix un missatge de validació "El nombre es obligatorio"
    And no s'insereix cap registre a la BD

  Scenario: Crear un hàbit amb nom massa curt
    Given l'usuari és al formulari de creació d'hàbit
    When introdueix "A" al camp nom (menys de 2 caràcters)
    And prem "Crear hábito"
    Then apareix un missatge "Mínimo 2 caracteres"
    And no s'insereix cap registre a la BD

  Scenario: Preview en temps real
    Given l'usuari és al formulari de creació d'hàbit
    When escriu "Meditació" al camp nom
    Then la targeta de preview mostra "Meditació" actualitzat en temps real
```

### 8.2 Proves d'edició d'hàbits

```gherkin
Feature: Edició d'un hàbit existent

  Scenario: Editar el nom d'un hàbit
    Given existeix un hàbit "Llegir" a la llista de l'usuari
    When prem la icona de llapis de l'hàbit
    And modifica el nom a "Llegir 20 minuts"
    And prem "Guardar cambios"
    Then la llista mostra el nom actualitzat "Llegir 20 minuts"
    And la taula "habit" a Supabase reflecteix el canvi

  Scenario: Editar la durada d'un hàbit
    Given existeix un hàbit amb durada de 15 min
    When l'usuari obre l'editor i selecciona 45 min
    And prem "Guardar cambios"
    Then la targeta mostra "45 min" com a nova durada

  Scenario: Cancel·lar l'edició
    Given l'usuari ha obert el formulari d'edició
    When prem la icona de tancament (X)
    Then es tanca el formulari sense aplicar canvis
    And la llista mostra les dades originals sense modificar
```

### 8.3 Proves d'eliminació d'hàbits

```gherkin
Feature: Eliminació d'un hàbit

  Scenario: Eliminar un hàbit amb confirmació
    Given existeix un hàbit "Córrer" a la llista
    When l'usuari prem la icona de paperera
    Then apareix un diàleg de confirmació "¿Eliminar hábito?"
    When confirma prement "Eliminar"
    Then l'hàbit desapareix de la llista
    And s'elimina el registre de "user_habit" a Supabase
    And s'elimina el registre de "habit" a Supabase (si cap altre usuari el té)

  Scenario: Cancel·lar l'eliminació
    Given existeix un hàbit a la llista
    When prem la icona de paperera
    And prem "Cancelar" al diàleg de confirmació
    Then el diàleg es tanca i l'hàbit es manté a la llista

  Scenario: L'hàbit eliminat no torna a aparèixer
    Given l'usuari ha eliminat l'hàbit "Meditació"
    When tanca l'aplicació i la torna a obrir
    Then "Meditació" no apareix a la llista d'hàbits
```

### 8.4 Proves de la pantalla principal

```gherkin
Feature: Pantalla principal (HomeScreen)

  Scenario: Estat buit sense hàbits
    Given l'usuari autenticat no té cap hàbit creat
    When accedeix a la pantalla principal
    Then es mostra el missatge "Sin hábitos todavía"
    And es mostra el text "Crea tu primer hábito..."

  Scenario: Salutació dinàmica
    Given l'usuari autenticat és a la pantalla principal
    When l'hora actual és entre les 08:00 i les 11:59
    Then la capçalera mostra "Buenos días"
    When l'hora actual és entre les 12:00 i les 18:59
    Then la capçalera mostra "Buenas tardes"
    When l'hora actual és entre les 19:00 i les 23:59
    Then la capçalera mostra "Buenas noches"

  Scenario: Logout amb confirmació
    Given l'usuari és a la pantalla principal
    When prem la icona de logout
    Then apareix un diàleg "¿Cerrar sesión?"
    When confirma prement "Salir"
    Then l'aplicació redirigeix a la pantalla de login
    And la sessió de Supabase queda tancada
```

📸 `[CAPTURA — HomeScreen amb hàbits i colors neon]`

📸 `[CAPTURA — Diàleg de confirmació d'eliminació]`

📸 `[CAPTURA — HabitFormScreen amb preview en temps real]`

📸 `[CAPTURA — Supabase Table Editor mostrant registres a habit i user_habit]`

---

## 9. Control de Versions i Seguiment

### 9.1 Control de versions

Els commits s'han registrat diàriament al repositori GitHub. La participació entre els membres del grup respecta la ràtio mínima **40/60** establerta a l'enunciat.

**Convencions de commits:**
- Missatges descriptius en català/castellà
- Un commit per funcionalitat o correcció significativa
- Branques: `main` com a branca principal

📸 `[CAPTURA — Historial de commits a GitHub (Insights → Contributors o log de commits)]`

### 9.2 Seguiment a Confluence

Tota la documentació d'aquesta fase es troba actualitzada a l'espai **Momentum** de Confluence, incloent les fases 1, 2 i 3 prèvies, la matriu de traçabilitat i els casos de prova en format Gherkin.

---

*Document generat durant el Sprint 2 — Momentum App © 2026*
