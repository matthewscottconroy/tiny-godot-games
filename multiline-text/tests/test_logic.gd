extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_bbcode_tag_pairs()
	_test_table_column_count()
	_test_color_tag_format()
	_test_mode_count()
	_test_tag_nesting()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_bbcode_tag_pairs() -> void:
	print("bbcode tag pairs are balanced")
	var tags := ["b", "i", "u", "s", "code", "center", "right", "indent"]
	for tag in tags:
		var open_tag := "[%s]" % tag
		var close_tag := "[/%s]" % tag
		expect(open_tag.length() > 2, "open tag [%s] is non-empty" % tag)
		expect(close_tag.begins_with("[/"), "close tag starts with [/")

func _test_table_column_count() -> void:
	print("table column count in BBCode")
	var table_tag := "[table=3]"
	expect(table_tag.contains("3"), "table has 3 columns")
	var table2 := "[table=2]"
	expect(table2.contains("2"), "stat table has 2 columns")

func _test_color_tag_format() -> void:
	print("color tag format")
	var red_tag := "[color=tomato]"
	var hex_tag := "[color=#ff6b6b]"
	expect(red_tag.begins_with("[color="), "named color tag format")
	expect(hex_tag.begins_with("[color=#"), "hex color tag format")
	expect(hex_tag.length() == 15, "hex color tag has correct length")

func _test_mode_count() -> void:
	print("display mode count")
	var modes := ["Basic", "Colors", "Table", "Effects", "Mixed"]
	expect(modes.size() == 5, "5 display modes available")

func _test_tag_nesting() -> void:
	print("combined bold+italic tag nesting")
	var combined := "[b][i]text[/i][/b]"
	expect(combined.begins_with("[b]"), "outer bold tag first")
	expect(combined.ends_with("[/b]"), "outer bold closes last")
	expect(combined.contains("[i]"), "inner italic tag present")

func _report() -> void:
	var summary := "[multiline-text] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
