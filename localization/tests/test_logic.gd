extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_all_locales_have_all_keys()
	_test_translation_round_trip()
	_test_locale_switch_changes_strings()
	_test_missing_key_returns_key()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# ---- data mirrored from main.gd ----

const KEYS := ["TITLE", "GREETING", "SCORE", "LIVES", "GAME_OVER", "START", "QUIT", "SETTINGS"]

const TRANSLATIONS := {
	"en": {
		"TITLE": "Adventure Quest", "GREETING": "Welcome, hero!",
		"SCORE": "Score", "LIVES": "Lives", "GAME_OVER": "Game Over",
		"START": "Start Game", "QUIT": "Quit", "SETTINGS": "Settings",
	},
	"es": {
		"TITLE": "Aventura Épica", "GREETING": "¡Bienvenido, héroe!",
		"SCORE": "Puntuación", "LIVES": "Vidas", "GAME_OVER": "Juego terminado",
		"START": "Iniciar juego", "QUIT": "Salir", "SETTINGS": "Ajustes",
	},
	"fr": {
		"TITLE": "Quête Aventure", "GREETING": "Bienvenue, héros!",
		"SCORE": "Score", "LIVES": "Vies", "GAME_OVER": "Partie terminée",
		"START": "Commencer", "QUIT": "Quitter", "SETTINGS": "Paramètres",
	},
}

# ---- helpers ----

func _build_translation_server() -> void:
	for locale in TRANSLATIONS:
		var tr := Translation.new()
		tr.locale = locale
		for k in TRANSLATIONS[locale]:
			tr.add_message(k, TRANSLATIONS[locale][k])
		TranslationServer.add_translation(tr)

# ---- tests ----

func _test_all_locales_have_all_keys() -> void:
	print("all locales have all 8 keys")
	for locale in TRANSLATIONS:
		for k in KEYS:
			expect(TRANSLATIONS[locale].has(k), "locale '%s' has key '%s'" % [locale, k])

func _test_translation_round_trip() -> void:
	print("Translation.add_message / translate round-trip")
	_build_translation_server()
	TranslationServer.set_locale("en")
	expect(TranslationServer.translate("TITLE") == "Adventure Quest", "en TITLE round-trip")
	TranslationServer.set_locale("es")
	expect(TranslationServer.translate("TITLE") == "Aventura Épica", "es TITLE round-trip")
	TranslationServer.set_locale("fr")
	expect(TranslationServer.translate("GREETING") == "Bienvenue, héros!", "fr GREETING round-trip")

func _test_locale_switch_changes_strings() -> void:
	print("locale switch changes returned strings")
	_build_translation_server()
	TranslationServer.set_locale("en")
	var en_start := TranslationServer.translate("START")
	TranslationServer.set_locale("es")
	var es_start := TranslationServer.translate("START")
	expect(en_start != es_start, "EN vs ES START differ")
	TranslationServer.set_locale("fr")
	var fr_start := TranslationServer.translate("START")
	expect(en_start != fr_start, "EN vs FR START differ")

func _test_missing_key_returns_key() -> void:
	print("missing key returns the key string itself")
	_build_translation_server()
	TranslationServer.set_locale("en")
	var result := TranslationServer.translate("NONEXISTENT_KEY_XYZ")
	# Godot returns the key when no translation is found
	expect(result == "NONEXISTENT_KEY_XYZ", "missing key returns key string")

func _report() -> void:
	var summary := "[localization] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
