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

var player         : Node  = null
var visible_flag   : bool  = false
var selected_ability: String = ""

var panel          : PanelContainer
var owned_btns     : Array = []
var slot_btns      : Array = []
var selected_lbl   : Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.anchor_left   = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left   = -300
	panel.offset_right  = 300
	panel.offset_top    = -220
	panel.offset_bottom = 220
	panel.visible = false
	add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "— INVENTARIO —"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	selected_lbl = Label.new()
	selected_lbl.text = "Selecciona una habilidad, luego un slot"
	selected_lbl.add_theme_font_size_override("font_size", 12)
	selected_lbl.add_theme_color_override("font_color", Color.CYAN)
	selected_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(selected_lbl)

	vbox.add_child(HSeparator.new())

	# Owned abilities (2 rows x 5 cols)
	var owned_lbl = Label.new()
	owned_lbl.text = "Habilidades en posesión:"
	owned_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(owned_lbl)

	var owned_grid = GridContainer.new()
	owned_grid.columns = 5
	vbox.add_child(owned_grid)

	for i in range(9):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 44)
		btn.text = "—"
		var capture_i = i
		btn.pressed.connect(func(): _select_ability_slot(capture_i))
		owned_grid.add_child(btn)
		owned_btns.append(btn)

	vbox.add_child(HSeparator.new())

	# Active slots
	var active_lbl = Label.new()
	active_lbl.text = "Slots activos (E / R / Q / 1 / 2 / 3):"
	active_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(active_lbl)

	var slot_hbox = HBoxContainer.new()
	slot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(slot_hbox)

	for i in range(6):
		var vb = VBoxContainer.new()
		vb.custom_minimum_size = Vector2(86, 0)
		slot_hbox.add_child(vb)

		var key_lbl = Label.new()
		key_lbl.text = "[%s]" % SLOT_KEYS[i]
		key_lbl.add_theme_font_size_override("font_size", 11)
		key_lbl.add_theme_color_override("font_color", Color.GRAY)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(key_lbl)

		var btn = Button.new()
		btn.text = "Vacío"
		btn.custom_minimum_size = Vector2(86, 44)
		var capture_i = i
		btn.pressed.connect(func(): _assign_to_slot(capture_i))
		vb.add_child(btn)
		slot_btns.append(btn)

	vbox.add_child(HSeparator.new())

	var hint = Label.new()
	hint.text = "[I] Cerrar"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

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
		if key != "":
			var data = ABILITY_DATA[key]
			btn.text = "%s\n%s" % [data["name"], _star_str(data["stars"])]
			btn.add_theme_color_override("font_color", data["color"])
		else:
			btn.text = "Vacío"
			btn.remove_theme_color_override("font_color")

func _selected_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color      = Color(0.2, 0.5, 0.2, 1)
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_color  = Color.CYAN
	return s

func _select_ability_slot(owned_idx: int) -> void:
	if not player:
		return
	if owned_idx >= player.owned_abilities.size():
		return
	selected_ability = player.owned_abilities[owned_idx]
	selected_lbl.text = "Seleccionado: %s → elige un slot" % ABILITY_DATA[selected_ability]["name"]
	_refresh()

func _assign_to_slot(slot_idx: int) -> void:
	if not player or selected_ability == "":
		return
	while player.active_slots.size() <= slot_idx:
		player.active_slots.append("")
	player.active_slots[slot_idx] = selected_ability
	selected_ability = ""
	selected_lbl.text = "¡Asignado! Selecciona otra habilidad"
	_refresh()
