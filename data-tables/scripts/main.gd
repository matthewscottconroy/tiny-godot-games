extends Control

const RARITY_COLOR := {
	"common":    Color(0.7, 0.7, 0.7),
	"uncommon":  Color(0.3, 0.85, 0.3),
	"rare":      Color(0.3, 0.5, 1.0),
	"legendary": Color(1.0, 0.7, 0.1),
}

var _db: ItemDB
var _filter := "all"
var _selected: ItemData = null

@onready var _list_box:   VBoxContainer = $MainPanel/HBox/LeftPane/ItemList
@onready var _detail_box: VBoxContainer = $MainPanel/HBox/RightPane/Detail
@onready var _filter_row: HBoxContainer = $MainPanel/FilterRow

func _ready() -> void:
	_db = ItemDB.new()  # populates itself in _init()

	var filter_defs := [
		["All",       "all"],
		["Weapons",   "weapon"],
		["Armor",     "armor"],
		["Consumable","consumable"],
		["Rare+",     "rare_plus"],
	]
	for fd in filter_defs:
		var btn := Button.new()
		btn.text = fd[0]
		btn.custom_minimum_size = Vector2(90, 32)
		var key: String = fd[1]
		btn.pressed.connect(func() -> void: _set_filter(key))
		_filter_row.add_child(btn)

	_refresh_list()

func _set_filter(f: String) -> void:
	_filter = f
	_selected = null
	_refresh_list()

func _get_filtered() -> Array[ItemData]:
	match _filter:
		"weapon":    return _db.filter_by_type("weapon")
		"armor":     return _db.filter_by_type("armor")
		"consumable":return _db.filter_by_type("consumable")
		"rare_plus":
			var out: Array[ItemData] = []
			for it in _db.items:
				if it.rarity in ["rare", "legendary"]:
					out.append(it)
			return out
	return _db.items

func _refresh_list() -> void:
	for child in _list_box.get_children():
		child.queue_free()
	for it in _get_filtered():
		var btn    := Button.new()
		var rc: Color = RARITY_COLOR.get(it.rarity, Color.WHITE)
		btn.text   = "%s  [%s]" % [it.item_name, it.rarity]
		btn.add_theme_color_override("font_color", rc)
		btn.custom_minimum_size = Vector2(0, 30)
		var capture := it
		btn.pressed.connect(func() -> void: _show_detail(capture))
		_list_box.add_child(btn)
	_show_detail(null)

func _show_detail(it: ItemData) -> void:
	_selected = it
	for child in _detail_box.get_children():
		child.queue_free()
	if not it:
		var lbl := Label.new()
		lbl.text = "Select an item"
		lbl.modulate = Color(1, 1, 1, 0.4)
		_detail_box.add_child(lbl)
		return

	var rc: Color = RARITY_COLOR.get(it.rarity, Color.WHITE)

	var name_lbl := Label.new()
	name_lbl.text = it.item_name
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", rc)
	_detail_box.add_child(name_lbl)

	for line in [
		"Type:   %s"   % it.item_type,
		"Value:  %d g" % it.value,
		"Weight: %.1f" % it.weight,
		"Rarity: %s"   % it.rarity,
		"",
		it.description,
	]:
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 13)
		_detail_box.add_child(lbl)
