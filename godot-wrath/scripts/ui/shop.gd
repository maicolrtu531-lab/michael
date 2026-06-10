extends CanvasLayer

const ABILITY_DATA = {
	"axe":      {"name": "Hacha",          "stars": 1, "mp": 15, "cd_var": "axe_cd",       "price": 0,   "color": Color(1.0, 0.7, 0.2, 1)},
	"blizzard": {"name": "Blizzard",       "stars": 2, "mp": 25, "cd_var": "blizzard_cd",  "price": 0,   "color": Color(0.4, 0.8, 1.0, 1)},
	"slam":     {"name": "Terremoto",      "stars": 3, "mp": 30, "cd_var": "slam_cd",      "price": 80,  "color": Color(0.9, 0.5, 0.1, 1)},
	"lightning":{"name": "Rayo",           "stars": 3, "mp": 20, "cd_var": "lightning_cd", "price": 100, "color": Color(1.0, 1.0, 0.3, 1)},
	"heal":     {"name": "Curación",       "stars": 3, "mp": 25, "cd_var": "heal_cd",      "price": 100, "color": Color(0.3, 1.0, 0.5, 1)},
	"shield":   {"name": "Escudo Divino",  "stars": 4, "mp": 20, "cd_var": "shield_cd",    "price": 150, "color": Color(0.3, 0.6, 1.0, 1)},
	"rage":     {"name": "Furia Espartana","stars": 4, "mp": 30, "cd_var": "rage_cd",      "price": 200, "color": Color(1.0, 0.3, 0.0, 1)},
	"meteor":   {"name": "Meteoro",        "stars": 5, "mp": 50, "cd_var": "meteor_cd",    "price": 350, "color": Color(1.0, 0.5, 0.0, 1)},
	"howl":     {"name": "Aullido Berserk","stars": 6, "mp": 60, "cd_var": "howl_cd",      "price": 600, "color": Color(0.8, 0.0, 1.0, 1)},
}

var player      : Node   = null
var visible_flag: bool   = false
var panel       : PanelContainer
var gold_lbl    : Label
var status_lbl  : Label
var item_rows   : Array  = []

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.anchor_left   = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left   = -260
	panel.offset_right  = 260
	panel.offset_top    = -260
	panel.offset_bottom = 260
	panel.visible = false
	add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "— TIENDA —"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	gold_lbl = Label.new()
	gold_lbl.text = "Oro: 0"
	gold_lbl.add_theme_color_override("font_color", Color.YELLOW)
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gold_lbl)

	vbox.add_child(HSeparator.new())

	# Consumables section
	var cons_lbl = Label.new()
	cons_lbl.text = "— Consumibles —"
	cons_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	cons_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cons_lbl)

	_add_consumable_row(vbox, "Poción de Salud  (+80 HP)", 30, Color(0.3, 1.0, 0.4, 1), "hp")
	_add_consumable_row(vbox, "Poción de Fuerza (+8 ATQ)", 80, Color(1.0, 0.6, 0.2, 1), "str")

	vbox.add_child(HSeparator.new())

	# Abilities section
	var ab_lbl = Label.new()
	ab_lbl.text = "— Habilidades —"
	ab_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	ab_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(ab_lbl)

	for key in ["slam", "lightning", "heal", "shield", "rage", "meteor", "howl"]:
		_add_ability_row(vbox, key)

	vbox.add_child(HSeparator.new())

	status_lbl = Label.new()
	status_lbl.text = "[B] Cerrar"
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_lbl)

func _add_consumable_row(parent: VBoxContainer, label_text: String, price: int, col: Color, item_key: String) -> void:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)

	var lbl = Label.new()
	lbl.custom_minimum_size = Vector2(240, 0)
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", 13)
	hbox.add_child(lbl)

	var btn = Button.new()
	btn.text = "%d G" % price
	btn.custom_minimum_size = Vector2(70, 0)
	btn.pressed.connect(func(): _buy_consumable(item_key, price))
	hbox.add_child(btn)

func _add_ability_row(parent: VBoxContainer, key: String) -> void:
	var data = ABILITY_DATA[key]
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	item_rows.append({"key": key, "hbox": hbox})

	var name_lbl = Label.new()
	name_lbl.custom_minimum_size = Vector2(140, 0)
	name_lbl.text = data["name"]
	name_lbl.add_theme_color_override("font_color", data["color"])
	name_lbl.add_theme_font_size_override("font_size", 13)
	hbox.add_child(name_lbl)

	var stars_lbl = Label.new()
	stars_lbl.custom_minimum_size = Vector2(80, 0)
	stars_lbl.text = _star_str(data["stars"])
	stars_lbl.add_theme_color_override("font_color", Color.GOLD)
	stars_lbl.add_theme_font_size_override("font_size", 11)
	hbox.add_child(stars_lbl)

	var btn = Button.new()
	btn.text = "%d G" % data["price"]
	btn.custom_minimum_size = Vector2(70, 0)
	btn.pressed.connect(func(): _buy_ability(key, data["price"]))
	hbox.add_child(btn)

func _star_str(stars: int) -> String:
	return "★".repeat(stars) + "☆".repeat(6 - stars)

func connect_player(p: Node) -> void:
	player = p

func toggle() -> void:
	visible_flag = not visible_flag
	panel.visible = visible_flag
	if visible_flag:
		_refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible_flag:
		toggle()

func _refresh() -> void:
	if not player:
		return
	gold_lbl.text = "Oro: %d" % player.gold
	for row in item_rows:
		var key  = row["key"]
		var hbox = row["hbox"]
		var owned = key in player.owned_abilities
		var btn : Button = hbox.get_child(2)
		if owned:
			btn.text     = "Comprado"
			btn.disabled = true
		else:
			btn.text     = "%d G" % ABILITY_DATA[key]["price"]
			btn.disabled = player.gold < ABILITY_DATA[key]["price"]

func _buy_consumable(item_key: String, price: int) -> void:
	if not player or player.gold < price:
		return
	player.gold -= price
	match item_key:
		"hp":  player.buy_health_potion()
		"str": player.buy_strength_potion()
	_refresh()
	_show_status("¡Comprado!")

func _buy_ability(key: String, price: int) -> void:
	if not player or player.gold < price:
		return
	if key in player.owned_abilities:
		return
	player.gold -= price
	player.add_owned_ability(key)
	_refresh()
	_show_status("¡Habilidad desbloqueada: %s!" % ABILITY_DATA[key]["name"])

func _show_status(msg: String) -> void:
	status_lbl.text = msg
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(status_lbl) and visible_flag:
		status_lbl.text = "[B] Cerrar"
