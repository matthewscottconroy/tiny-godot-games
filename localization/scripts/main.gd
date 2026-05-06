extends Control

const KEYS := ["TITLE", "GREETING", "SCORE", "LIVES", "GAME_OVER", "START", "QUIT", "SETTINGS"]

const TRANSLATIONS := {
	"en": {
		"TITLE": "Adventure Quest",
		"GREETING": "Welcome, hero!",
		"SCORE": "Score",
		"LIVES": "Lives",
		"GAME_OVER": "Game Over",
		"START": "Start Game",
		"QUIT": "Quit",
		"SETTINGS": "Settings",
	},
	"es": {
		"TITLE": "Aventura Épica",
		"GREETING": "¡Bienvenido, héroe!",
		"SCORE": "Puntuación",
		"LIVES": "Vidas",
		"GAME_OVER": "Juego terminado",
		"START": "Iniciar juego",
		"QUIT": "Salir",
		"SETTINGS": "Ajustes",
	},
	"fr": {
		"TITLE": "Quête Aventure",
		"GREETING": "Bienvenue, héros!",
		"SCORE": "Score",
		"LIVES": "Vies",
		"GAME_OVER": "Partie terminée",
		"START": "Commencer",
		"QUIT": "Quitter",
		"SETTINGS": "Paramètres",
	},
}

var _current_locale := "en"

func _ready() -> void:
	for locale in TRANSLATIONS:
		var tr := Translation.new()
		tr.locale = locale
		for k in TRANSLATIONS[locale]:
			tr.add_message(k, TRANSLATIONS[locale][k])
		TranslationServer.add_translation(tr)
	TranslationServer.set_locale("en")

	$VBox/LangRow/BtnEN.pressed.connect(func(): _set_locale("en"))
	$VBox/LangRow/BtnES.pressed.connect(func(): _set_locale("es"))
	$VBox/LangRow/BtnFR.pressed.connect(func(): _set_locale("fr"))

	_refresh_ui()

func _set_locale(loc: String) -> void:
	_current_locale = loc
	TranslationServer.set_locale(loc)
	_refresh_ui()

func _refresh_ui() -> void:
	$VBox/TitleLabel.text        = TranslationServer.translate("TITLE")
	$VBox/GreetingLabel.text     = TranslationServer.translate("GREETING")
	$VBox/CurrentLangLabel.text  = "Locale: " + _current_locale

	var grid: GridContainer = $VBox/Grid
	# Rows: key labels (col 0) + value labels (col 1)
	# Child order: key0, val0, key1, val1 ...
	var children := grid.get_children()
	var idx := 0
	for k in KEYS:
		if idx + 1 < children.size():
			(children[idx] as Label).text     = k
			(children[idx + 1] as Label).text = TranslationServer.translate(k)
		idx += 2

	$VBox/LangRow/BtnEN.text = TranslationServer.translate("START").substr(0, 0) + "English"
	$VBox/LangRow/BtnES.text = "Español"
	$VBox/LangRow/BtnFR.text = "Français"
