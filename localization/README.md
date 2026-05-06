# Localization

Demonstrates Godot 4.2's `TranslationServer` and `Translation` resource: register string tables for English, Spanish, and French in code, then switch locales at runtime and watch all UI labels update instantly.

## Purpose

Localization is mandatory for any game targeting more than one language market. The hidden complexity is not in translating strings — it is in the engineering: keeping translated strings separate from UI layout, making locale switches propagate automatically, handling missing keys gracefully, and not hard-coding any user-visible text directly in script. Godot's `TranslationServer` provides the machinery for all of this.

This demo builds its translation tables entirely in code (no `.csv` or `.po` files) to keep the project self-contained and make the API visible. In a production project you would load `.po` files instead, but the `TranslationServer` calls are identical. Understanding how `Translation.add_message`, `TranslationServer.add_translation`, and `TranslationServer.translate` relate to each other is the transferable knowledge — the file format is just a different way to fill the same data structure.

## How It Works

### Building Translation Objects at Startup

```gdscript
func _ready() -> void:
    for locale in TRANSLATIONS:
        var tr := Translation.new()
        tr.locale = locale
        for k in TRANSLATIONS[locale]:
            tr.add_message(k, TRANSLATIONS[locale][k])
        TranslationServer.add_translation(tr)
    TranslationServer.set_locale("en")
    _refresh_ui()
```

Each `Translation` object holds all strings for one locale. `add_message(key, value)` registers a key–value pair. After all three are registered, `set_locale("en")` makes English the active locale, and `_refresh_ui()` pushes the translated strings to the scene's Label nodes.

### Switching Locales

```gdscript
func _set_locale(loc: String) -> void:
    _current_locale = loc
    TranslationServer.set_locale(loc)
    _refresh_ui()
```

`set_locale` changes the active locale globally. It does **not** automatically re-translate existing Label text — you must manually re-query and reassign every label. `_refresh_ui()` does this by calling `TranslationServer.translate(key)` for each UI element.

### Querying Translations

```gdscript
$VBox/TitleLabel.text    = TranslationServer.translate("TITLE")
$VBox/GreetingLabel.text = TranslationServer.translate("GREETING")
```

`TranslationServer.translate("KEY")` returns the string for the current locale. Inside a Node script, `tr("KEY")` is the idiomatic shorthand and is identical. This demo uses the full form to make the API explicit.

### Missing Key Fallback

When a key has no translation in the current locale, `translate()` returns the key string itself — `"NONEXISTENT_KEY_XYZ"` becomes the visible text. This is intentional: it makes untranslated strings immediately visible during development without crashing.

```gdscript
# Verified in test_logic.gd:
expect(TranslationServer.translate("NONEXISTENT_KEY_XYZ") == "NONEXISTENT_KEY_XYZ",
    "missing key returns key string")
```

## Key Table

| Key | English | Spanish | French |
|-----|---------|---------|--------|
| TITLE | Adventure Quest | Aventura Épica | Quête Aventure |
| GREETING | Welcome, hero! | ¡Bienvenido, héroe! | Bienvenue, héros! |
| SCORE | Score | Puntuación | Score |
| LIVES | Lives | Vidas | Vies |
| GAME_OVER | Game Over | Juego terminado | Partie terminée |
| START | Start Game | Iniciar juego | Commencer |
| QUIT | Quit | Salir | Quitter |
| SETTINGS | Settings | Ajustes | Paramètres |

## Production Workflow: .po Files

In a real project, skip the inline Dictionary and use `.po` files instead:

1. Create `locale/en.po`, `locale/es.po`, `locale/fr.po`.
2. Each file uses standard gettext format: `msgid "TITLE"` / `msgstr "Adventure Quest"`.
3. Godot auto-imports `.po` files as `Translation` resources — they appear in `ProjectSettings > Localization`.
4. The `tr("TITLE")` call works identically, but you never write `TranslationServer.add_translation()` manually.

The `.po` workflow also enables the `TranslationServer.locale_changed` signal, which fires automatically when the locale changes — subscribe to it in UI nodes to auto-refresh labels without calling `_refresh_ui()` explicitly.

## Locale Code Reference

Godot uses IETF BCP 47 language tags. Common codes:

| Code | Language |
|------|----------|
| `en` | English |
| `es` | Spanish |
| `fr` | French |
| `de` | German |
| `ja` | Japanese |
| `zh_CN` | Simplified Chinese |
| `pt_BR` | Brazilian Portuguese |
| `ko` | Korean |

## How to Adapt This in Your Project

- **Auto-refresh on locale change**: Connect `TranslationServer.locale_changed` signal to `_refresh_ui()` so you don't have to call it manually after every `set_locale()`.
- **Export to .csv**: Maintain a spreadsheet with `Key,en,es,fr` columns. Godot's import system converts `.csv` files directly to Translation resources when the first column is the key.
- **Plurals**: `.po` format supports plural forms (`msgid_plural` / `msgstr[0]` / `msgstr[1]`); use `TranslationServer.translate_plural(key, count)` to query them.
- **RTL languages**: Set `Control.layout_direction = Control.LAYOUT_DIRECTION_RTL` for Arabic and Hebrew; Godot handles text mirroring automatically when the locale is set to an RTL language.
- **Font substitution**: Store fonts per locale in a Dictionary and swap `theme.default_font` in `_set_locale()` for languages that need different character sets (CJK, Cyrillic, Arabic).

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Translation.new()` | Create a translation table for one locale |
| `Translation.locale` | Set the locale code (e.g., `"es"`) |
| `Translation.add_message(key, value)` | Register a key–string pair |
| `TranslationServer.add_translation(tr)` | Register a Translation object globally |
| `TranslationServer.set_locale(code)` | Switch the active locale |
| `TranslationServer.translate(key)` | Get translated string for the current locale |
| `tr(key)` | Node-level shorthand for `TranslationServer.translate` |

## Controls

| Button | Action |
|--------|--------|
| English | Switch to English locale (`en`) |
| Español | Switch to Spanish locale (`es`) |
| Français | Switch to French locale (`fr`) |

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Translation table, locale switching, UI refresh |
| `tests/test_logic.gd` | Unit tests: all-keys coverage, round-trip, locale switch, missing-key fallback |
| `scenes/main.tscn` | Control scene with VBox, Labels, and language buttons |
| `tests/test.tscn` | Test runner scene |
