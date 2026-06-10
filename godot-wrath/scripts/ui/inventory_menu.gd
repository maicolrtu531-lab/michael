extends CanvasLayer

const ABILITY_DATA = {
	"axe":      {"name": "Hacha",          "stars": 1, "mp": 15, "color": Color(1.0, 0.7, 0.2, 1)},
	"blizzard": {"name": "Blizzard",       "stars": 2, "mp": 25, "color": Color(0.4, 0.8, 1.0, 1)},
	"slam":     {"name": "Terremoto",      "stars": 3, "mp": 30, "color": Color(0.9, 0.5, 0.1, 1)},
	"lightning":{"name": "Rayo",           "stars": 3, "mp": 20, "color": Color(1.0, 1.0, 0.3, 1)},
	"heal":     {"name": "Curación",       "stars": 3, "mp": 25, "color": Color(0.3, 1.0, 0.5, 1)},
	"shield":   {"name": "Escudo Divino",  "stars": 4, "mp": 20, "color": Color(0.3, 0.6, 1.0, 1)},
	"rage":     {"name": "Furia Espartana","stars": 4, "mp": 30, "color": Color(1.0, 0.3, 0.0, 1)},
	"meteor":   {"name": "Meteoro",        "stars": 5, "mp": 50, "color": Color(1.0, 0.5, 0.0, 1)},
	"howl":     {"name": "Aullido Berserk","stars": 6, "mp": 60, "color": Color(0.8, 0.0, 1.0, 1)},
}

const SLOT_KEYS = ["E", "R", "Q", "1", "2", "3"]

var player          : Node   = null
var visible_flag    : bool   = false
var selected_ability: String = ""

var panel           : PanelContainer
var tabs            : TabContainer
var status_lbl      : Label
var owned_btns      : Array  = []
var slot_btns       : Array  = []
var weapon_list     : VBoxContainer
var armor_list      : VBoxContainer
var potion_lbl      : Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.anchor_left   = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left   = -340
	panel.offset_right  = 340
	panel.offset_top    = -240
	panel.offset_bottom = 240
	panel.visible = false
	add_child(panel)

	var root_vbox = VBoxContainer.new()
	panel.add_child(root_vbox)

	var title = Label.new()
	title.text = "— INVENTARIO —"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title)

	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(0, 380)
	root_vbox.add_child(tabs)

	_build_tab_poderes()
	_build_tab_armas()
	_build_tab_armadura()
	_build_tab_pociones()

	status_lbl = Label.new()
	status_lbl.text = "[I] Cerrar"
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.add_theme_color_override("font_color", Color.GRAY)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(status_lbl)

func _build_tab_poderes() -> void:
	var vbox = VBoxContainer.new()
	vbox.name = "Poderes"
	tabs.add_child(vbox)

	var hint = Label.new()
	hint.text = "Selecciona → luego haz clic en un slot activo"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color.CYAN)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	var grid = GridContainer.new()
	grid.columns = 5
	vbox.add_child(grid)

	for i in range(9):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(110, 48)
		btn.text = "—"
		var ci = i
		btn.pressed.connect(func(): _select_ability_slot(ci))
		grid.add_child(btn)
		owned_btns.append(btn)

	vbox.add_child(HSeparator.new())

	var slots_lbl = Label.new()
	slots_lbl.text = "Slots activos:"
	slots_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(slots_lbl)

	var slot_hbox = HBoxContainer.new()
	slot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(slot_hbox)

	for i in range(6):
		var vb = VBoxContainer.new()
		vb.custom_minimum_size = Vector2(90, 0)
		slot_hbox.add_child(vb)

		var key_lbl = Label.new()
		key_lbl.text = "[%s]" % SLOT_KEYS[i]
		key_lbl.add_theme_font_size_override("font_size", 11)
		key_lbl.add_theme_color_override("font_color", Color.GRAY)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(key_lbl)

		var btn = Button.new()
		btn.text = "Vacío"
		btn.custom_minimum_size = Vector2(90, 44)
		var ci = i
		btn.pressed.connect(func(): _assign_to_slot(ci))
		vb.add_child(btn)
		slot_btns.append(btn)

func _build_tab_armas() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Armas"
	tabs.add_child(scroll)
	weapon_list = VBoxContainer.new()
	weapon_list.custom_minimum_size = Vector2(600, 0)
	scroll.add_child(weapon_list)

func _build_tab_armadura() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Armadura"
	tabs.add_child(scroll)
	armor_list = VBoxContainer.new()
	armor_list.custom_minimum_size = Vector2(600, 0)
	scroll.add_child(armor_list)

func _build_tab_pociones() -> void:
	var vbox = VBoxContainer.new()
	vbox.name = "Pociones"
	tabs.add_child(vbox)

	potion_lbl = Label.new()
	potion_lbl.text = "Pociones de salud: 0"
	potion_lbl.add_theme_font_size_override("font_size", 16)
	potion_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1))
	potion_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(potion_lbl)

	var use_btn = Button.new()
	use_btn.text = "Usar poción (F)"
	use_btn.custom_minimum_size = Vector2(200, 40)
	use_btn.pressed.connect(func():
		if player: player.use_potion()
		_refresh()
	)
	vbox.add_child(use_btn)

func _star_str(stars: int) -> String:
	return "★".repeat(stars) + "☆".repeat(6 - stars)

func connect_player(p: Node) -> void:
	player = p

func toggle() -> void:
	visible_flag = not visible_flag
	panel.visible = visible_flag
	selected_ability = ""
	if visible_flag:
		_refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible_flag:
		toggle()

func _refresh() -> void:
	if not player:
		return

	# Poderes tab
	var owned = player.owned_abilities
	for i in range(owned_btns.size()):
		var btn : Button = owned_btns[i]
		if i < owned.size():
			var key  = owned[i]
			var data = ABILITY_DATA[key]
			btn.text = "%s\n%s %dMP" % [data["name"], _star_str(data["stars"]), data["mp"]]
			btn.add_theme_color_override("font_color", data["color"])
			btn.disabled = false
			if key == selected_ability:
				btn.add_theme_stylebox_override("normal", _selected_style())
			else:
				btn.remove_theme_stylebox_override("normal")
		else:
			btn.text = "—"
			btn.disabled = true
			btn.remove_theme_stylebox_override("normal")

	var slots = player.active_slots
	for i in range(slot_btns.size()):
		var btn : Button = slot_btns[i]
		var key = slots[i] if i < slots.size() else ""
		if key != "" and key in ABILITY_DATA:
			var data = ABILITY_DATA[key]
			btn.text = "%s\n%s" % [data["name"], _star_str(data["stars"])]
			btn.add_theme_color_override("font_color", data["color"])
		else:
			btn.text = "Vacío"
			btn.remove_theme_color_override("font_color")

	# Armas tab
	for c in weapon_list.get_children():
		c.queue_free()
	if player.inventory_weapons.is_empty():
		var lbl = Label.new()
		lbl.text = "Sin armas — los enemigos dropean armas"
		lbl.add_theme_color_override("font_color", Color.GRAY)
		weapon_list.add_child(lbl)
	else:
		for i in range(player.inventory_weapons.size()):
			var w = player.inventory_weapons[i]
			var hbox = HBoxContainer.new()
			weapon_list.add_child(hbox)
			var lbl = Label.new()
			lbl.custom_minimum_size = Vector2(300, 0)
			var equipped = player.equipped_weapon == w
			lbl.text = "[E] " if equipped else "     "
			lbl.text += "%s  %s  +%d ATQ" % [w["name"], _star_str(w["stars"]), w["damage_bonus"]]
			lbl.add_theme_color_override("font_color", Color.GOLD if equipped else Color.WHITE)
			hbox.add_child(lbl)
			var btn = Button.new()
			btn.text = "Equipar" if not equipped else "Equipado"
			btn.disabled = equipped
			var ci = i
			btn.pressed.connect(func():
				player.equip_weapon(ci)
				_refresh()
			)
			hbox.add_child(btn)

	# Armadura tab
	for c in armor_list.get_children():
		c.queue_free()
	if player.inventory_armor.is_empty():
		var lbl = Label.new()
		lbl.text = "Sin armadura — los enemigos dropean armaduras"
		lbl.add_theme_color_override("font_color", Color.GRAY)
		armor_list.add_child(lbl)
	else:
		for i in range(player.inventory_armor.size()):
			var a = player.inventory_armor[i]
			var hbox = HBoxContainer.new()
			armor_list.add_child(hbox)
			var lbl = Label.new()
			lbl.custom_minimum_size = Vector2(300, 0)
			var equipped = player.equipped_armor == a
			lbl.text = "[E] " if equipped else "     "
			lbl.text += "%s  %s  +%d DEF" % [a["name"], _star_str(a["stars"]), a["defense_bonus"]]
			lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1) if equipped else Color.WHITE)
			hbox.add_child(lbl)
			var btn = Button.new()
			btn.text = "Equipar" if not equipped else "Equipado"
			btn.disabled = equipped
			var ci = i
			btn.pressed.connect(func():
				player.equip_armor(ci)
				_refresh()
			)
			hbox.add_child(btn)

	# Pociones tab
	if potion_lbl:
		potion_lbl.text = "Pociones de salud: %d" % player.potions

func _selected_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.5, 0.2, 1)
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_color = Color.CYAN
	return s

func _select_ability_slot(owned_idx: int) -> void:
	if not player or owned_idx >= player.owned_abilities.size():
		return
	selected_ability = player.owned_abilities[owned_idx]
	status_lbl.text = "Seleccionado: %s → elige un slot" % ABILITY_DATA[selected_ability]["name"]
	_refresh()

func _assign_to_slot(slot_idx: int) -> void:
	if not player or selected_ability == "":
		return
	while player.active_slots.size() <= slot_idx:
		player.active_slots.append("")
	player.active_slots[slot_idx] = selected_ability
	selected_ability = ""
	status_lbl.text = "¡Asignado!"
	_refresh()
