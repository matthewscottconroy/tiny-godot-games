extends Node

# Drives the real catalogue from scripts/catalogue.gd — see
# docs/TEST_INTEGRITY.md.
#
# The browser reads the collection off disk, so the suite points it at the real
# collection: if the README index changes shape, this fails rather than the
# browser quietly showing an empty list.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_finds_the_collection()
	_test_every_entry_is_a_real_demo()
	_test_entries_carry_their_category()
	_test_entries_carry_a_description()
	_test_tags_are_read_from_each_demo()
	_test_search_matches_names_and_descriptions()
	_test_search_is_case_insensitive()
	_test_an_empty_search_shows_everything()
	_test_a_search_that_matches_nothing_is_empty()
	_test_filtering_by_tag()
	_test_search_and_tag_together()
	_test_the_tag_list_is_sorted_and_unique()
	_test_a_missing_collection_is_handled()
	await _test_the_window_holds_the_whole_layout()
	await _test_the_panel_follows_the_selection()
	_test_reading_a_demo_with_no_tags()
	_test_headings_lose_their_emoji()
	await _test_the_keys_the_window_handles()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[browser] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const Catalogue := preload("res://scripts/catalogue.gd")

var _root: String = ProjectSettings.globalize_path("res://..")
var _entries: Array = []

func _load() -> Array:
	if _entries.is_empty():
		_entries = Catalogue.load_from(_root)
	return _entries

func _test_it_finds_the_collection() -> void:
	print("the collection")
	var entries := _load()
	expect(entries.size() > 100, "the browser reads the whole collection (%d demos)" % entries.size())

func _test_every_entry_is_a_real_demo() -> void:
	print("real folders")
	var entries := _load()
	var missing := 0
	for entry in entries:
		# A row in the index naming a folder that is not there would show a
		# demo that cannot be launched.
		if not DirAccess.dir_exists_absolute(_root.path_join(entry.name)):
			missing += 1
	expect(missing == 0, "every listed demo is a folder that exists")

func _test_entries_carry_their_category() -> void:
	print("categories")
	var entries := _load()
	var categories := {}
	for entry in entries:
		categories[entry.category] = true
		expect_quiet(entry.category != "" and entry.category != "Uncategorised",
			"%s has no category" % entry.name)
	expect(_quiet_failures == 0, "every demo carries the category it is indexed under")
	expect(categories.size() > 5, "and the categories are the index's, not one bucket")

func _test_entries_carry_a_description() -> void:
	print("descriptions")
	var entries := _load()
	begin_quiet()
	for entry in entries:
		expect_quiet(entry.description.length() > 10, "%s has no description" % entry.name)
	expect(_quiet_failures == 0, "every demo carries its one-line description")

func _test_tags_are_read_from_each_demo() -> void:
	print("tags")
	var entries := _load()
	var tagged := 0
	for entry in entries:
		if entry.tags.size() > 0:
			tagged += 1
	# Read from each demo's own README rather than a list here, so the browser
	# cannot disagree with tools/build_tags.py.
	expect(tagged > 100, "most demos come with tags (%d of %d)" % [tagged, entries.size()])

func _test_search_matches_names_and_descriptions() -> void:
	print("searching")
	var entries := _load()
	var by_name := Catalogue.filter(entries, "coyote", "")
	expect(by_name.size() >= 1, "a search matches a demo by name")
	var found := false
	for entry in by_name:
		if entry.name == "coyote-time":
			found = true
	expect(found, "and finds the one it names")

	var by_text := Catalogue.filter(entries, "jump buffering", "")
	expect(by_text.size() >= 1, "a search matches words from a description too")

func _test_search_is_case_insensitive() -> void:
	print("case")
	var entries := _load()
	expect(Catalogue.filter(entries, "COYOTE", "").size()
		== Catalogue.filter(entries, "coyote", "").size(),
		"searching is case insensitive")

func _test_an_empty_search_shows_everything() -> void:
	print("no search")
	var entries := _load()
	expect(Catalogue.filter(entries, "", "").size() == entries.size(),
		"an empty search hides nothing")
	expect(Catalogue.filter(entries, "   ", "").size() == entries.size(),
		"and neither does a search of spaces")

func _test_a_search_that_matches_nothing_is_empty() -> void:
	print("no matches")
	var entries := _load()
	expect(Catalogue.filter(entries, "zzzzz-not-a-demo", "").is_empty(),
		"a search matching nothing returns nothing rather than everything")

func _test_filtering_by_tag() -> void:
	print("tag filter")
	var entries := _load()
	var shaders := Catalogue.filter(entries, "", "shader")
	expect(shaders.size() > 0, "filtering by a tag finds demos")
	begin_quiet()
	for entry in shaders:
		expect_quiet(entry.tags.has("shader"), "%s does not carry the tag" % entry.name)
	expect(_quiet_failures == 0, "and every one of them carries it")
	expect(shaders.size() < entries.size(), "while leaving the rest out")

func _test_search_and_tag_together() -> void:
	print("both at once")
	var entries := _load()
	var both := Catalogue.filter(entries, "shader", "shader")
	begin_quiet()
	for entry in both:
		expect_quiet(entry.tags.has("shader"), "%s slipped past the tag" % entry.name)
		expect_quiet(entry.haystack().to_lower().contains("shader"),
			"%s slipped past the search" % entry.name)
	expect(_quiet_failures == 0, "a search and a tag together apply both, not either")

func _test_the_tag_list_is_sorted_and_unique() -> void:
	print("the tag bar")
	var entries := _load()
	var tags := Catalogue.tags_in(entries)
	expect(tags.size() > 5, "there are tags to filter by")
	var seen := {}
	var sorted := true
	var previous := ""
	for tag in tags:
		if seen.has(tag):
			expect(false, "the tag list repeats %s" % tag)
		seen[tag] = true
		if previous != "" and tag < previous:
			sorted = false
		previous = tag
	expect(sorted, "the tag list is in order, so the buttons do not move about")

func _test_a_missing_collection_is_handled() -> void:
	print("no collection")
	# Run from somewhere without a README, the browser should come up empty and
	# say so rather than failing to open.
	expect(Catalogue.load_from("/nonexistent-directory").is_empty(),
		"a missing collection reads as no demos rather than an error")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")

# --- the real scene ----------------------------------------------------------

## Every control has to fit inside the window.
##
## A container cannot be squeezed below its minimum size, so one row of fourteen
## tag buttons — 1255px of them — made the whole layout wider than the 900px
## window and Godot centred the overflow, pushing the demo list off the left
## edge and the detail panel off the right. Nothing errored; the browser simply
## showed a column of blank rows.
##
## Checking the geometry rather than the tag bar specifically, because the next
## thing to overflow will not be the tag bar.
func _test_the_window_holds_the_whole_layout() -> void:
	print("the window")
	var window := get_window()
	window.size = Vector2i(900, 620)
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var view := get_viewport().get_visible_rect()
	var overflowing: Array[String] = []
	_collect_overflow(scene, view, overflowing)
	expect(overflowing.is_empty(),
		"nothing is laid out beyond the window (%s)"
		% ("all inside" if overflowing.is_empty() else ", ".join(overflowing)))

	# The tag bar is the one that overflowed, so pin the property that fixed it:
	# it must be free to wrap rather than committed to a single row.
	var bar: Control = scene.get_node("Layout/Tags")
	expect(bar.get_child_count() > 5, "the tag bar carries a button per tag (%d)" % bar.get_child_count())
	expect(bar.get_combined_minimum_size().x < view.size.x,
		"the tag bar's minimum width fits the window (%.0f < %.0f)"
		% [bar.get_combined_minimum_size().x, view.size.x])
	expect(bar.get_global_rect().size.y > bar.get_child(0).get_global_rect().size.y,
		"the tag bar wrapped onto more than one row")

	scene.queue_free()

func _collect_overflow(node: Node, view: Rect2, out: Array[String]) -> void:
	if node is Control:
		var rect: Rect2 = (node as Control).get_global_rect()
		if rect.position.x < view.position.x - 0.5 \
				or rect.position.y < view.position.y - 0.5 \
				or rect.end.x > view.end.x + 0.5 \
				or rect.end.y > view.end.y + 0.5:
			out.append("%s %s" % [node.name, rect])
	for child in node.get_children():
		_collect_overflow(child, view, out)

## The detail panel and the launch button, driven through the real scene.
func _test_the_panel_follows_the_selection() -> void:
	print("the panel")
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame

	var launch: Button = scene.get_node("Layout/Body/Detail/Launch")
	var title: Label = scene.get_node("Layout/Body/Detail/Title")
	expect(not launch.disabled, "a demo is selected on open, so Launch is live")

	# Nothing matches: there is no demo to launch, and offering the button
	# anyway would launch whatever was selected before the search.
	scene._search.text = "zzzz-no-such-demo"
	scene._refresh()
	expect(launch.disabled, "a search that matches nothing disables Launch")
	expect(title.text == "Nothing matches", "and the panel says so")

	scene._search.text = ""
	scene._refresh()
	expect(not launch.disabled, "clearing the search brings it back")

	# An index one past the end is what an ItemList reports after the list has
	# shrunk under it, so the guard has to reject it rather than let it through.
	var shown_before: String = title.text
	scene._on_selected(scene._shown.size())
	expect(title.text == shown_before, "an index past the end leaves the panel alone")
	scene._on_selected(-1)
	expect(title.text == shown_before, "and so does a negative one")

	# Exactly one tag can be active, so pressing one has to release the others.
	var bar: Control = scene.get_node("Layout/Tags")
	var physics: Button = null
	for child in bar.get_children():
		if (child as Button).text == "physics":
			physics = child
	expect(physics != null, "there is a physics tag button")
	# "all" is the tag that is active on open, so it starts down and the rest
	# start up — the opposite would show every filter as already applied.
	var all_button: Button = bar.get_child(0)
	expect(all_button.text == "all", "the first tag button is `all`")
	expect(all_button.button_pressed, "which starts pressed, since no filter is applied")
	if physics != null:
		expect(not physics.button_pressed, "and the others start unpressed")
	if physics != null:
		physics.pressed.emit()
		var pressed := 0
		for child in bar.get_children():
			if (child as Button).button_pressed:
				pressed += 1
		expect(pressed == 1, "pressing a tag releases every other one (%d pressed)" % pressed)
		expect(physics.button_pressed, "and leaves the one that was pressed down")

	# Both Enters launch — a numpad Enter is still an Enter.
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	var kp_enter := InputEventKey.new()
	kp_enter.keycode = KEY_KP_ENTER
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	expect(scene.is_launch_key(enter), "Enter launches")
	expect(scene.is_launch_key(kp_enter), "and so does the numpad Enter")
	expect(not scene.is_launch_key(escape), "Escape does not")

	scene.queue_free()

## Seven demos are tagged `none` rather than carrying a tag list, and the parser
## has to treat that the same as having no tag line at all — not as a demo whose
## one tag is the word "none".
func _test_reading_a_demo_with_no_tags() -> void:
	print("no tags")
	var untagged := Catalogue._tags_of(_root.path_join("grid-movement"))
	expect(untagged.is_empty(), "a demo tagged `none` reports no tags (%s)" % [untagged])

	var absent := Catalogue._tags_of(_root.path_join("no-such-demo-at-all"))
	expect(absent.is_empty(), "and so does a directory with no README")

	var tagged := Catalogue._tags_of(_root.path_join("bouncing-ball"))
	expect(not tagged.is_empty(), "while a tagged demo still reports its tags (%s)" % [tagged])

	# And the panel has to say something for it, rather than an empty line.
	var entries := _load()
	var without: Array = entries.filter(func(e): return e.tags.is_empty())
	expect(without.size() > 0, "the collection has demos with no tags (%d)" % without.size())

	# Every tag is listed once, and listing depends on the seen-set actually
	# remembering — a set that records "no" grows a duplicate per demo.
	var all_tags := Catalogue.tags_in(entries)
	var unique := {}
	for tag in all_tags:
		unique[tag] = true
	expect(all_tags.size() == unique.size(),
		"each tag appears once in the bar (%d listed, %d distinct)" % [all_tags.size(), unique.size()])

func _test_headings_lose_their_emoji() -> void:
	print("headings")
	# The index headings carry an emoji for the web view. The list wants the
	# words, and only the words — the emoji sit above U+2000, everything in the
	# heading text sits below it.
	expect(Catalogue._strip_emoji("🎮 Movement & Platforming") == "Movement & Platforming",
		"the emoji is dropped and the words kept")
	expect(Catalogue._strip_emoji("Movement & Platforming") == "Movement & Platforming",
		"a heading with no emoji is unchanged")
	expect(Catalogue._strip_emoji("⚙️ Physics & Simulation") == "Physics & Simulation",
		"including one whose emoji has a variation selector")

	# Every category the real index produced has to survive the strip.
	_quiet_failures = 0
	for entry in _load():
		expect_quiet(entry.category.strip_edges() == entry.category and entry.category != "",
			"%s has a clean category (%s)" % [entry.name, entry.category])
	expect(_quiet_failures == 0, "every entry came out with a readable category")

## Escape clears the search. Driven through the handler rather than by calling
## _refresh(), so the guard that rejects non-key events is covered too — and
## Enter is deliberately not sent here, since launching starts a real process.
func _test_the_keys_the_window_handles() -> void:
	print("the keys")
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame

	# Nothing here may start a real process. A mutant can send any key down the
	# launch path, and a windowed Godot that outlives the run hangs the harness.
	var launched: Array = []
	scene.spawn = func(executable: String, args: PackedStringArray) -> int:
		launched.append([executable, args])
		return 4321

	scene._search.text = "wall"
	scene._refresh()
	var narrowed: int = scene._shown.size()
	expect(narrowed < _load().size(), "a search narrows the list (%d)" % narrowed)

	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	scene._unhandled_key_input(escape)
	expect(scene._search.text == "", "Escape clears the search")
	expect(scene._shown.size() > narrowed, "and the whole list comes back")

	scene._search.text = "wall"
	scene._refresh()
	scene._unhandled_key_input(InputEventMouseButton.new())
	expect(scene._search.text == "wall", "a mouse event is not mistaken for a key")

	var released := InputEventKey.new()
	released.keycode = KEY_ESCAPE
	released.pressed = false
	scene._unhandled_key_input(released)
	expect(scene._search.text == "wall", "and neither is a key coming back up")

	# Enter, now that it is safe to send: it has to reach the launcher with the
	# selected demo's own directory, since --path is what makes each folder
	# standalone.
	scene._search.text = ""
	scene._refresh()
	var wanted: String = scene._shown[0].name
	var enter_key := InputEventKey.new()
	enter_key.keycode = KEY_ENTER
	enter_key.pressed = true
	scene._unhandled_key_input(enter_key)
	expect(launched.size() == 1, "Enter launches exactly one process (%d)" % launched.size())
	if launched.size() == 1:
		var args: PackedStringArray = launched[0][1]
		expect(args.size() == 2 and args[0] == "--path",
			"it is started with --path, not a scene (%s)" % [args])
		expect(args.size() == 2 and args[1].ends_with(wanted),
			"pointing at the selected demo (%s, wanted %s)" % [args[1] if args.size() == 2 else "", wanted])
		expect(scene._status.text.contains(wanted), "and the status line names it")

	# Escape is not a launch key, so it must not have added a second one.
	scene._unhandled_key_input(escape)
	expect(launched.size() == 1, "Escape does not launch anything")

	# A refused spawn returns 0 or -1, and the status line has to say so rather
	# than reporting a pid that does not exist. This is the state inside an
	# exported build, where create_process is unavailable.
	scene.spawn = func(_e: String, _a: PackedStringArray) -> int: return -1
	scene._launch_selected()
	expect(scene._status.text.to_lower().contains("could not launch"),
		"a refused launch says so (%s)" % scene._status.text)
	scene.spawn = func(_e: String, _a: PackedStringArray) -> int: return 0
	scene._launch_selected()
	expect(scene._status.text.to_lower().contains("could not launch"),
		"and so does a zero pid (%s)" % scene._status.text)

	# The panel shows "no tags" rather than an empty line for an untagged demo.
	var untagged_name := ""
	for entry in scene._entries:
		if entry.tags.is_empty():
			untagged_name = entry.name
			break
	expect(untagged_name != "", "the collection has an untagged demo to select")
	if untagged_name != "":
		scene._search.text = untagged_name
		scene._refresh()
		expect(scene._tags_label.text == "no tags",
			"an untagged demo reads `no tags` (%s)" % scene._tags_label.text)
		scene._search.text = "bouncing-ball"
		scene._refresh()
		expect(scene._tags_label.text != "no tags" and scene._tags_label.text != "",
			"a tagged one lists them (%s)" % scene._tags_label.text)

	scene.queue_free()
