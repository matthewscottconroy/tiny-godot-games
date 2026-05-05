extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	var db := ItemDB.new()
	db._ready()
	test_db_populated(db)
	test_find_by_name(db)
	test_find_missing_returns_null(db)
	test_filter_by_type_weapon(db)
	test_filter_by_type_consumable(db)
	test_filter_by_rarity_legendary(db)
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[data-tables] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

func test_db_populated(db: ItemDB) -> void:
	expect(db.items.size() > 0, "database has items")
	expect(db.items.size() == 10, "database has exactly 10 items")

func test_find_by_name(db: ItemDB) -> void:
	var sword := db.find_by_name("Iron Sword")
	expect(sword != null,            "find_by_name returns item when found")
	expect(sword.item_type == "weapon", "Iron Sword is a weapon")
	expect(sword.rarity == "common",    "Iron Sword is common")

func test_find_missing_returns_null(db: ItemDB) -> void:
	var result := db.find_by_name("Unobtainium Blade")
	expect(result == null, "find_by_name returns null for unknown item")

func test_filter_by_type_weapon(db: ItemDB) -> void:
	var weapons := db.filter_by_type("weapon")
	expect(weapons.size() > 0, "there are weapons in the database")
	for w in weapons:
		expect(w.item_type == "weapon", "%s is of type weapon" % w.item_name)

func test_filter_by_type_consumable(db: ItemDB) -> void:
	var consumables := db.filter_by_type("consumable")
	expect(consumables.size() > 0, "there are consumables in the database")
	for c in consumables:
		expect(c.item_type == "consumable", "%s is a consumable" % c.item_name)

func test_filter_by_rarity_legendary(db: ItemDB) -> void:
	var legends := db.filter_by_rarity("legendary")
	expect(legends.size() > 0, "there are legendary items")
	for l in legends:
		expect(l.rarity == "legendary", "%s is legendary" % l.item_name)
