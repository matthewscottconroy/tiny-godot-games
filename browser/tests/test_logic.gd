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
