# Copilot Instructions for FlowState

## Project Overview

FlowState is a HarmonyOS 6.0.2 (API Level 22) focus & task management app written in **ArkTS**. The single module is `flow/`. Build and run via **DevEco Studio** with the hvigor build system — there are no npm/gradle scripts.

## Architecture

### Startup Sequence (`FlowAbility.onCreate`)
The order in `flowability/FlowAbility.ets` is mandatory:
1. `PreferencesHelper.init(context)` — opens the preferences store synchronously
2. `AppStorage.setOrCreate(KEY_APP_LANGUAGE, ...)` — must be set **before** any page loads
3. `ThemeHelper.initFromStorage()` — restores theme tokens into AppStorage before UI mounts
4. `I18nHelper.init(context)` — preloads all rawfile JSON translation maps

### Directory Layout (`flow/src/main/ets/`)
| Directory | Purpose |
|---|---|
| `pages/` | `@Entry` page components (routable via `router.pushUrl`) |
| `views/` | Reusable `@Component` view structs (not directly routable) |
| `viewmodel/` | Static ViewModel classes — all business logic lives here, not in views |
| `util/` | Pure helper classes (`I18nHelper`, `ThemeHelper`, `PreferencesHelper`, `SpreadEffectHelper`) |
| `constants/` | `AppConstants.ets`, `I18nKeys.ets`, `ThemeConstants.ets` |
| `flowability/` | `UIAbility` entry point |

### Navigation
- Entry: `pages/Index.ets` → `MainPage` (2-tab bottom nav)
  - Tab 0: `views/HomePage.ets`
  - Tab 1: `views/HistoryPage.ets`
- Settings entry via `router.pushUrl({ url: 'pages/SettingsPage' })` from HomePage header icon
- Sub-pages: `SettingsPage` → `LanguagePage`, `ThemePage`

## Key Systems

### i18n
- Translations live in `flow/src/main/resources/rawfile/i18n/zh_CN.json` and `en_US.json`
- All string keys are declared as enum values in `constants/I18nKeys.ets` — never use raw string literals
- Call pattern: `I18nHelper.t(I18nKeys.SOME_KEY, this.currentLanguage)`
- The `lang` parameter **must** be `this.currentLanguage` (the `@StorageLink` field), not a local variable — ArkUI's dependency tracker needs to see the reactive reference to trigger re-renders on language switch
- Adding a string: add to both JSON files, then add a constant to `I18nKeys`

### Theme System
- All colors come from a `ThemeTokens` object — **never hardcode color values** in components
- Components subscribe via `@StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS`
- Apply theme changes through `ThemeHelper.applyTheme(themeId)` or `ThemeViewModel.setTheme(themeId)` — this pushes a new object reference to AppStorage, triggering all subscribers
- Preset themes: `light`, `dark`, `warm`, `ocean`, `forest` — defined in `ThemeConstants.ets`
- Custom theme: derived from 3 base colors (bg, textPrimary, accent) via `ThemeHelper.buildCustomTokens()`

### Persistence
- `PreferencesHelper` wraps `@kit.ArkData preferences` with a sync-read / async-flush pattern
- Read: `getPreferencesSync` → `getSync` (synchronous, safe to call at startup)
- Write: `putSync` (in-memory) + `.flush()` (async disk write) — always both together
- The preferences file name is `PREFS_STORE_NAME = 'app_preferences'`

### Click Spread Effect
- All interactive rows/tabs use `SpreadEffectHelper.trigger(...)` for the horizontal rectangle spread animation
- Because ArkUI state must belong to the component, pass setter callbacks instead of shared state — see `SpreadEffectHelper.ets` for the exact signature

## Conventions

### Naming (from `docs/CODE.md`)
- Classes & interfaces: `PascalCase`
- Methods & variables: `camelCase`
- Constants & enums: `UPPER_SNAKE_CASE`
- `@State`/`@Prop` variable names must have clear business semantics (e.g., `isTaskRunning` not `running`)
- **All inline comments and block comments must be written in Chinese**

### AppStorage Keys
All keys must be declared as named string constants in `constants/AppConstants.ets`. Never write key strings inline in components.

### ArkTS Constraints (critical differences from TypeScript)
- **No `any` or `unknown`** — every value must have a concrete type
- **No `var`** — use `let`/`const`; all variables must be initialized at declaration
- **No dynamic property addition** — object shapes are fixed at compile time
- **No `delete` operator** — set to `undefined` or use optional properties instead
- **No `#` private fields** — use the `private` keyword
- **No prototype modification**, no `eval()`
- **No TypeScript utility types** (`Partial`, `Pick`, `Omit`, `Required`, etc.) — not available in ArkTS
- **No conditional/mapped types or template literal types**
- Type assertions use `value as T` syntax only — angle-bracket style (`<T>value`) is not supported
- UI components use `struct`, not `class`; structs cannot extend other structs
- `build()` must have exactly one root element and no variable declarations inside it

### Imports
- HarmonyOS SDK: always use `@kit.*` namespaces (e.g., `@kit.ArkUI`, `@kit.AbilityKit`)
- Named imports only — no wildcard `import *`
- Default imports only for native NAPI modules (e.g., `import testNapi from 'libflow.so'`)

### Icons & Assets
- **No emojis** anywhere in the UI
- Use only verified system icons — check `E:\DevEco Studio\sdk\default\openharmony\ets\build-tools\ets-loader\sysResource.js` before referencing `sys.media.*`
- Known missing icons (use custom SVG instead):
  - `ohos_ic_public_home` → use `$r('app.media.ic_tab_home')`
  - `ohos_ic_public_settings` → use `$r('app.media.ic_settings')`
- Custom SVGs go in `flow/src/main/resources/base/media/`, referenced as `$r('app.media.icon_name')`
- SVGs must use `viewBox="0 0 24 24"` and `fill="currentColor"` for tinting support

### Divider API Quirk
`Divider.strokeWidth()` accepts `number | string` only — **not** `Resource`. Always use the constant:
```typescript
import { DIVIDER_STROKE_WIDTH } from '../constants/AppConstants';
Divider().strokeWidth(DIVIDER_STROKE_WIDTH)  // '0.5vp'
```
Never pass `$r('app.float.xxx')` to `strokeWidth`.

## Design Principles (from PRD)
- **Cardless design**: no shadow-bordered cards, no heavy color blocks; use typography contrast, whitespace, and thin dividers for visual hierarchy
- **Flat task structure**: no project→task→subtask nesting
- **Smooth & Snappy**: state transitions use 300ms animations (`animationDuration(300)`); never instant or sluggish
- All global style variables (spacing, font sizes, colors) go through `$r('app.float.*')` resources or `ThemeTokens` — no hardcoded pixel values in components
