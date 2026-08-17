extends Node

# Drives the real RichTextLabel content from scenes/main.tscn — see
# docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_opens_on_the_basics()
	_test_each_button_shows_its_own_page()
	_test_switching_replaces_rather_than_appends()
	_test_the_label_parses_bbcode()
	_test_every_tag_is_closed()
	_test_the_table_rows_are_the_width_it_declares()
	_test_the_pages_demonstrate_what_they_claim()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[multiline-text] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Control:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _press(m: Control, name: String) -> void:
	(m.get_node("Buttons/" + name) as Button).pressed.emit()

func _buttons(m: Control) -> Array[Button]:
	var found: Array[Button] = []
	for child in m.get_node("Buttons").get_children():
		if child is Button:
			found.append(child)
	return found

## Tags that stand alone rather than wrapping anything.
const SELF_CLOSING := ["br", "img"]

## Drop [code]...[/code] spans, whose contents are tag names shown as text.
##
## The pages explain BBCode by printing it, so "[code][b][/code]" is three
## characters of prose rather than an unclosed bold.
func _without_code_spans(text: String) -> String:
	var out := ""
	var rest := text
	while true:
		var open := rest.find("[code]")
		if open == -1:
			return out + rest
		var close := rest.find("[/code]", open)
		if close == -1:
			return out + rest.substr(0, open)
		out += rest.substr(0, open)
		rest = rest.substr(close + 7)
	return out

## Every opening tag in `text` that never gets a matching closer.
func _unclosed_tags(raw: String) -> Array[String]:
	var text := _without_code_spans(raw)
	var open_counts := {}
	var start := 0
	while true:
		var lt := text.find("[", start)
		if lt == -1:
			break
		var gt := text.find("]", lt)
		if gt == -1:
			break
		var body := text.substr(lt + 1, gt - lt - 1)
		start = gt + 1
		if body.is_empty():
			continue
		var name := body.split("=")[0].split(" ")[0]
		if SELF_CLOSING.has(name) or SELF_CLOSING.has(body):
			continue
		if body.begins_with("/"):
			var closing := body.substr(1)
			open_counts[closing] = int(open_counts.get(closing, 0)) - 1
		else:
			open_counts[name] = int(open_counts.get(name, 0)) + 1
	var leftovers: Array[String] = []
	for name in open_counts:
		if int(open_counts[name]) != 0:
			leftovers.append("%s (%d)" % [name, open_counts[name]])
	return leftovers

func _test_it_opens_on_the_basics() -> void:
	print("on open")
	var m := _make()
	expect(m.rich.text.length() > 0, "there is something on screen before any button is pressed")
	expect(m.rich.text.contains("[b]"), "and it is the formatting page")

func _test_each_button_shows_its_own_page() -> void:
	print("the buttons")
	var m := _make()
	var seen := {}
	for button in _buttons(m):
		button.pressed.emit()
		seen[m.rich.text] = button.name
	expect(seen.size() == _buttons(m).size(), "every button shows a different page")

func _test_switching_replaces_rather_than_appends() -> void:
	print("switching pages")
	var m := _make()
	_press(m, "ColorsBtn")
	var colours: String = m.rich.text
	_press(m, "TableBtn")
	expect(not m.rich.text.contains(colours), "a new page replaces the last rather than piling up")
	_press(m, "ColorsBtn")
	expect(m.rich.text == colours, "and going back shows the same page again")

func _test_the_label_parses_bbcode() -> void:
	print("the label")
	var m := _make()
	# Without this the markup is displayed literally, tags and all.
	expect(m.rich.bbcode_enabled, "the label is set to interpret BBCode rather than print it")

func _test_every_tag_is_closed() -> void:
	print("balanced markup")
	var m := _make()
	for button in _buttons(m):
		button.pressed.emit()
		var leftovers := _unclosed_tags(m.rich.text)
		expect(leftovers.is_empty(),
			"%s leaves no tag unclosed%s" % [button.name,
				"" if leftovers.is_empty() else " — " + ", ".join(leftovers)])

func _test_the_table_rows_are_the_width_it_declares() -> void:
	print("the table page")
	var m := _make()
	_press(m, "TableBtn")
	# The page also mentions "[table=columns]" as prose inside a code span, so
	# the real table is found after those are stripped out.
	var text: String = _without_code_spans(m.rich.text)
	var columns := 0
	var marker := text.find("[table=")
	expect(marker != -1, "the page has a table")
	if marker == -1:
		return
	columns = int(text.substr(marker + 7, text.find("]", marker) - marker - 7))
	expect(columns > 0, "declaring how many columns it has")

	var cells := text.count("[cell]")
	expect(cells > 0, "with cells in it")
	expect(cells % columns == 0,
		"and the cells fill whole rows (%d cells across %d columns)" % [cells, columns])

func _test_the_pages_demonstrate_what_they_claim() -> void:
	print("page contents")
	var m := _make()
	_press(m, "ColorsBtn")
	expect(m.rich.text.contains("[color="), "the colours page uses colour tags")
	_press(m, "EffectsBtn")
	expect(m.rich.text.contains("[wave") or m.rich.text.contains("[shake"),
		"the effects page uses animated tags")
	_press(m, "BasicBtn")
	expect(m.rich.text.contains("[i]"), "and the basics page covers italics")
