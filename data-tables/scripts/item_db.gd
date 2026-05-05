class_name ItemDB
extends Node

var items: Array[ItemData] = []

func _ready() -> void:
	_populate()

func _populate() -> void:
	items = [
		_make("Iron Sword",    "weapon",    50,  3.5, "common",    Color(0.7, 0.7, 0.8),  "A reliable iron blade."),
		_make("Fire Staff",    "weapon",   320,  4.0, "rare",      Color(1.0, 0.5, 0.1),  "Launches fireballs."),
		_make("Void Blade",    "weapon",  1200,  6.5, "legendary", Color(0.3, 0.1, 0.8),  "Tears reality apart."),
		_make("Wooden Shield", "armor",     20,  5.0, "common",    Color(0.6, 0.4, 0.2),  "Splinters easily."),
		_make("Steel Buckler", "armor",     80,  2.0, "common",    Color(0.6, 0.6, 0.7),  "A compact shield."),
		_make("Dragon Scale",  "armor",    800,  8.0, "legendary", Color(0.8, 0.2, 0.1),  "Scales from Ignaros."),
		_make("Speed Boots",   "armor",    150,  1.5, "uncommon",  Color(0.3, 0.8, 0.3),  "Doubles movement speed."),
		_make("Health Potion", "consumable", 25, 0.5, "common",    Color(1.0, 0.3, 0.3),  "Restores 50 HP."),
		_make("Mega Elixir",   "consumable",500, 1.0, "rare",      Color(0.5, 0.0, 0.8),  "Fully restores HP and MP."),
		_make("Smoke Bomb",    "consumable", 40, 0.3, "uncommon",  Color(0.4, 0.4, 0.4),  "Creates a blinding cloud."),
	]

func _make(n: String, t: String, v: int, w: float, r: String, c: Color, d: String) -> ItemData:
	var it := ItemData.new()
	it.item_name   = n;  it.item_type = t;  it.value  = v
	it.weight      = w;  it.rarity    = r;  it.color  = c;  it.description = d
	return it

func find_by_name(n: String) -> ItemData:
	for it in items:
		if it.item_name == n:
			return it
	return null

func filter_by_type(t: String) -> Array[ItemData]:
	var out: Array[ItemData] = []
	for it in items:
		if it.item_type == t:
			out.append(it)
	return out

func filter_by_rarity(r: String) -> Array[ItemData]:
	var out: Array[ItemData] = []
	for it in items:
		if it.rarity == r:
			out.append(it)
	return out
