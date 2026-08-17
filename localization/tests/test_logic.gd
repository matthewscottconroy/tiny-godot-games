extends Node

# Drives the real translation table from scenes/main.tscn — see
# docs/TEST_INTEGRITY.md.
#
# TranslationServer is global, so the suite puts the locale back when it is
# done — a leftover would change what every later demo sees.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_every_language_has_every_key()
	_test_the_languages_are_actually_different()
	_test_the_translations_are_registered_with_godot()
	_test_it_opens_in_english()
	_test_switching_language_changes_the_text()
	_test_the_language_buttons_switch()
	_test_the_key_list_is_shown_with_its_translations()
	_test_an_unknown_key_comes_back_as_itself()
	_test_a_short_grid_is_left_alone()
	_report()
	TranslationServer.set_locale("en")

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[localization] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Control

func _make() -> Control:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _label(m: Control, path: String) -> Label:
	return m.get_node("VBox/" + path)

func _test_every_language_has_every_key() -> void:
	print("coverage")
	var m := _make()
	expect(m.TRANSLATIONS.size() > 1, "there is more than one language")
	for locale in m.TRANSLATIONS:
		var table: Dictionary = m.TRANSLATIONS[locale]
		for key in m.KEYS:
			# A missing key shows the raw key on screen, which is how half-
			# translated games end up displaying GAME_OVER to a player.
			expect_quiet(table.has(key), "%s is missing %s" % [locale, key])
			expect_quiet(table.get(key, "") != "", "%s has %s blank" % [locale, key])
	expect(_quiet_failures == 0, "every language translates every key")

func _test_the_languages_are_actually_different() -> void:
	print("distinct languages")
	var m := _make()
	var locales: Array = m.TRANSLATIONS.keys()
	for key in m.KEYS:
		var values := {}
		for locale in locales:
			values[m.TRANSLATIONS[locale][key]] = true
		expect_quiet(values.size() > 1, "%s reads the same in every language" % key)
	expect(_quiet_failures == 0, "the languages differ from each other, key by key")

func _test_the_translations_are_registered_with_godot() -> void:
	print("registration")
	var m := _make()
	# Held in a dictionary and never handed to the TranslationServer, the table
	# would be documentation rather than a translation.
	TranslationServer.set_locale("es")
	expect(TranslationServer.translate("TITLE") == m.TRANSLATIONS["es"]["TITLE"],
		"the server returns the Spanish title")
	TranslationServer.set_locale("en")

func _test_it_opens_in_english() -> void:
	print("the default")
	var m := _make()
	expect(m._current_locale == "en", "the demo opens in English")
	expect(_label(m, "TitleLabel").text == m.TRANSLATIONS["en"]["TITLE"], "with the English title")

func _test_switching_language_changes_the_text() -> void:
	print("switching")
	var m := _make()
	var english: String = _label(m, "TitleLabel").text
	m._set_locale("fr")
	expect(m._current_locale == "fr", "the locale changes")
	expect(_label(m, "TitleLabel").text != english, "and the title with it")
	expect(_label(m, "TitleLabel").text == m.TRANSLATIONS["fr"]["TITLE"], "to the French one")
	expect(_label(m, "GreetingLabel").text == m.TRANSLATIONS["fr"]["GREETING"],
		"and every other visible string too")
	expect(_label(m, "CurrentLangLabel").text.contains("fr"), "with the readout naming the language")
	m._set_locale("en")

func _test_the_language_buttons_switch() -> void:
	print("the buttons")
	var m := _make()
	(m.get_node("VBox/LangRow/BtnES") as Button).pressed.emit()
	expect(m._current_locale == "es", "the Spanish button switches to Spanish")
	(m.get_node("VBox/LangRow/BtnEN") as Button).pressed.emit()
	expect(m._current_locale == "en", "and the English button back to English")

func _test_the_key_list_is_shown_with_its_translations() -> void:
	print("the table")
	var m := _make()
	var grid: GridContainer = m.get_node("VBox/Grid")
	var children := grid.get_children()
	expect(children.size() >= m.KEYS.size() * 2, "the grid has a row per key")
	for i in m.KEYS.size():
		var key_label := children[i * 2] as Label
		var value_label := children[i * 2 + 1] as Label
		expect_quiet(key_label.text == m.KEYS[i], "row %d names its key" % i)
		expect_quiet(value_label.text == m.TRANSLATIONS["en"][m.KEYS[i]],
			"row %d shows the translation beside it" % i)
	expect(_quiet_failures == 0, "each row pairs a key with its translation")

	# And the values follow the language, rather than being whatever the scene
	# file happened to be saved with.
	m._set_locale("es")
	for i in m.KEYS.size():
		var value_label := grid.get_children()[i * 2 + 1] as Label
		expect_quiet(value_label.text == m.TRANSLATIONS["es"][m.KEYS[i]],
			"row %d is not in Spanish" % i)
	expect(_quiet_failures == 0, "and the whole table switches language together")
	m._set_locale("en")

func _test_an_unknown_key_comes_back_as_itself() -> void:
	print("missing keys")
	_make()
	expect(TranslationServer.translate("NO_SUCH_KEY") == "NO_SUCH_KEY",
		"an untranslated key falls back to itself rather than an empty string")

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, ")")

func _test_a_short_grid_is_left_alone() -> void:
	print("a grid with a missing cell")
	var m := _make()
	var grid: GridContainer = m.get_node("VBox/Grid")
	# One cell short of a full pair. The fill loop has to stop rather than
	# write half a row and run off the end of the list.
	var last: Node = grid.get_children()[grid.get_child_count() - 1]
	grid.remove_child(last)
	last.free()

	var final_key := grid.get_children()[grid.get_child_count() - 1] as Label
	final_key.text = "UNTOUCHED"
	m._refresh_ui()
	expect(final_key.text == "UNTOUCHED", "the incomplete row is skipped, not half-written")
