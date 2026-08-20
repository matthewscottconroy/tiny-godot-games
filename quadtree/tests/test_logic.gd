extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_insert_and_query()
	_test_query_miss()
	_test_subdivision()
	_test_max_depth()
	_test_clear()
	_test_the_children_tile_the_parent()
	_test_each_quadrant_holds_its_own()
	_test_an_object_spans_the_quadrants_it_overlaps()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[quadtree] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make_obj(x: float, y: float, r: float = 5.0) -> Dictionary:
	return {"pos": Vector2(x, y), "radius": r}

# ──────────────────────── Tests ────────────────────────

func _test_insert_and_query() -> void:
	print("Test: insert 3 objects, query all")
	var qt := QTNode.new(Rect2(0, 0, 100, 100))
	qt.insert(_make_obj(10, 10))
	qt.insert(_make_obj(50, 50))
	qt.insert(_make_obj(80, 80))
	var result := qt.query(Rect2(0, 0, 100, 100))
	expect(result.size() == 3, "query returns 3 objects (got %d)" % result.size())

func _test_query_miss() -> void:
	print("Test: query area with no objects")
	var qt := QTNode.new(Rect2(0, 0, 100, 100))
	qt.insert(_make_obj(10, 10))
	qt.insert(_make_obj(20, 20))
	# Query bottom-right quadrant where no objects exist
	var result := qt.query(Rect2(60, 60, 40, 40))
	expect(result.size() == 0, "query miss returns 0 (got %d)" % result.size())

func _test_subdivision() -> void:
	print("Test: insert MAX_OBJECTS+1 → subdivides")
	var qt := QTNode.new(Rect2(0, 0, 100, 100))
	# Insert MAX_OBJECTS+1 objects in the same area
	for i in range(QTNode.MAX_OBJECTS + 1):
		qt.insert(_make_obj(25.0 + i * 0.5, 25.0 + i * 0.5))
	expect(qt.children.size() == 4, "node subdivided into 4 children (got %d)" % qt.children.size())

func _test_max_depth() -> void:
	print("Test: no subdivision beyond MAX_DEPTH")
	# Create a node already at MAX_DEPTH
	var qt := QTNode.new(Rect2(0, 0, 10, 10), QTNode.MAX_DEPTH)
	# Insert more than MAX_OBJECTS
	for i in range(QTNode.MAX_OBJECTS + 5):
		qt.insert(_make_obj(5.0 + randf() * 0.01, 5.0 + randf() * 0.01))
	expect(qt.children.size() == 0, "no subdivision at MAX_DEPTH (got %d children)" % qt.children.size())

func _test_clear() -> void:
	print("Test: clear empties tree")
	var qt := QTNode.new(Rect2(0, 0, 100, 100))
	qt.insert(_make_obj(10, 10))
	qt.insert(_make_obj(50, 50))
	qt.insert(_make_obj(80, 80))
	qt.clear()
	var result := qt.query(Rect2(0, 0, 100, 100))
	expect(result.size() == 0, "after clear, query returns 0 (got %d)" % result.size())
	expect(qt.children.size() == 0, "after clear, no children remain")

## The four children cover the parent exactly, with no gap and no overlap.
##
## Every test above roots the tree at (0, 0), where the quadrant offsets are the
## only thing distinguishing `x + hw` from `x - hw` — and a child placed outside
## the parent still leaves the tree *looking* right: it has four children, the
## count is correct, and objects that should have landed in it simply vanish.
## Rooted somewhere arbitrary, the geometry has to be checked directly.
func _test_the_children_tile_the_parent() -> void:
	print("Test: the four children tile the parent")
	var root := Rect2(200, 140, 80, 60)
	var qt := QTNode.new(root)
	for i in range(QTNode.MAX_OBJECTS + 1):
		qt.insert(_make_obj(root.position.x + 5.0 + i * 0.5, root.position.y + 5.0 + i * 0.5))
	expect(qt.children.size() == 4, "it subdivided (%d children)" % qt.children.size())

	var half := root.size * 0.5
	var expected := [
		Rect2(root.position, half),
		Rect2(root.position + Vector2(half.x, 0.0), half),
		Rect2(root.position + Vector2(0.0, half.y), half),
		Rect2(root.position + half, half),
	]
	var quiet := 0
	for want in expected:
		var found := false
		for c in qt.children:
			if c.bounds.position.is_equal_approx(want.position) \
					and c.bounds.size.is_equal_approx(want.size):
				found = true
		if not found:
			quiet += 1
			print("    (no child at ", want, ")")
	expect(quiet == 0, "each quadrant sits where it should")

	# Every child is inside the parent, and their areas add back up to it — a
	# quadrant placed outside would satisfy neither.
	var covered := 0.0
	for c in qt.children:
		expect_quiet(root.encloses(c.bounds), "%s is inside the root" % c.bounds)
		covered += c.bounds.size.x * c.bounds.size.y
	expect(is_equal_approx(covered, root.size.x * root.size.y),
		"the four together cover the parent exactly (%.0f of %.0f)"
		% [covered, root.size.x * root.size.y])
	expect(_quiet_failures == 0, "and none of them hangs outside it")

	# Depth increases downward, or the recursion guard never bites — this is the
	# demo that once recursed without bound on that exact mistake.
	for c in qt.children:
		expect_quiet(c.depth == qt.depth + 1, "child depth is %d" % c.depth)
	expect(_quiet_failures == 0, "every child is one level deeper than its parent")

	# get_all_rects() is what the demo draws, and it draws leaves only: a
	# subdivided node hands back its children's rectangles instead of its own,
	# or the picture shows one box over the top of the four inside it.
	var drawn: Array = qt.get_all_rects()
	expect(drawn.size() >= 4, "the tree reports a rectangle per leaf (%d)" % drawn.size())
	var has_root := false
	for r in drawn:
		if (r as Rect2).size.is_equal_approx(root.size):
			has_root = true
	expect(not has_root, "and not the whole root on top of them")
	var total := 0.0
	for r in drawn:
		total += (r as Rect2).size.x * (r as Rect2).size.y
	expect(is_equal_approx(total, root.size.x * root.size.y),
		"the leaves tile the root exactly once (%.0f of %.0f)"
		% [total, root.size.x * root.size.y])

## An object goes into the quadrant it is standing in, and a query for that
## quadrant finds it there.
func _test_each_quadrant_holds_its_own() -> void:
	print("Test: objects land in the right quadrant")
	var root := Rect2(200, 140, 80, 60)
	var qt := QTNode.new(root)
	# Enough to force a subdivision, all in the top-left so they end up together.
	for i in range(QTNode.MAX_OBJECTS + 1):
		qt.insert(_make_obj(root.position.x + 8.0 + i * 0.5, root.position.y + 8.0 + i * 0.5))

	var half := root.size * 0.5
	var corners := {
		"top-left": root.position + half * 0.5,
		"top-right": root.position + Vector2(half.x * 1.5, half.y * 0.5),
		"bottom-left": root.position + Vector2(half.x * 0.5, half.y * 1.5),
		"bottom-right": root.position + half * 1.5,
	}
	for name in corners:
		var at: Vector2 = corners[name]
		qt.insert({"pos": at, "radius": 1.0})
		var found := qt.query(Rect2(at - Vector2(2, 2), Vector2(4, 4)))
		expect_quiet(found.size() >= 1, "%s at %s is findable" % [name, at])
	expect(_quiet_failures == 0, "an object in every quadrant can be found again")

	# And a query of one quadrant does not return another quadrant's objects.
	var top_right: Vector2 = corners["top-right"]
	var near := qt.query(Rect2(top_right - Vector2(3, 3), Vector2(6, 6)))
	expect(near.size() == 1,
		"a query near the top-right corner finds only what is there (%d)" % near.size())

## An object straddling a boundary goes into every quadrant it overlaps.
##
## The object's box is built from its centre and radius. Offset it by the radius
## instead of centring it, and an object near a boundary is filed on the wrong
## side — which shows up as a collision that is never checked.
func _test_an_object_spans_the_quadrants_it_overlaps() -> void:
	print("Test: an object on a boundary lands in both")
	var root := Rect2(200, 140, 80, 60)
	var qt := QTNode.new(root)
	for i in range(QTNode.MAX_OBJECTS + 1):
		qt.insert(_make_obj(root.position.x + 8.0 + i * 0.5, root.position.y + 8.0 + i * 0.5))

	var middle := root.position + root.size * 0.5
	var straddler := {"pos": Vector2(middle.x, root.position.y + 8.0), "radius": 6.0}
	qt.insert(straddler)

	# Counted across the whole tree, not just the root's children: a quadrant
	# that has itself subdivided keeps its objects in its own children.
	var holding := _leaves_holding(qt, straddler)
	expect(holding >= 2,
		"an object sitting on the vertical divide is filed under both sides (%d)" % holding)

	# A small object well inside one quadrant belongs to that one alone. Placed
	# off-centre deliberately: the exact centre of a subdivided quadrant lies on
	# both of its own dividing lines, and lands in all four of its children.
	var tucked := {"pos": root.position + Vector2(30.0, 22.0), "radius": 1.0}
	qt.insert(tucked)
	var sole := _leaves_holding(qt, tucked)
	expect(sole == 1, "one well inside a quadrant is filed once (%d)" % sole)

## How many nodes in the tree are holding this exact object.
func _leaves_holding(node: QTNode, obj: Dictionary) -> int:
	var count := 0
	for o in node.objects:
		if o == obj:
			count += 1
	for c in node.children:
		count += _leaves_holding(c, obj)
	return count

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("    (", label, " — failed)")
