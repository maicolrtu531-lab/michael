extends CanvasLayer

var player : Node = null
var visible_flag : bool = false

var panel       : PanelContainer
var points_lbl  : Label
var stat_labels : Array = []
var stat_btns   : Array = []

const STATS = [
	{"key": "Fuerza",        "var": "base_damage", "inc": 4,   "label": "Ataque"},
	{"key": "Vitalidad",     "var": "max_hp",      "inc": 25,  "label": "Vida máx"},
	{"key": "Agilidad",      "var": "move_speed",  "inc": 0.6, "label": "Velocidad"},
	{"key": "Inteligencia",  "var": "max_mana",    "inc": 12,  "label": "Maná máx"},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.anchor_left   = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left   = -160
	panel.offset_right  = 160
	panel.offset_top    = -180
	panel.offset_bottom = 180
	panel.visible = false
	add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "— ESTADÍSTICAS —"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	points_lbl = Label.new()
	points_lbl.text = "Puntos: 0"
	points_lbl.add_theme_color_override("font_color", Color.CYAN)
	points_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(points_lbl)

	vbox.add_child(HSeparator.new())

	for i in range(STATS.size()):
		var s    = STATS[i]
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)

		var lbl = Label.new()
		lbl.custom_minimum_size = Vector2(220, 0)
		lbl.text = "%s: —" % s["label"]
		lbl.add_theme_font_size_override("font_size", 14)
		hbox.add_child(lbl)
		stat_labels.append(lbl)

		var btn = Button.new()
		btn.text = "+ (%d pts)" % (i + 1)
		btn.custom_minimum_size = Vector2(90, 0)
		var idx = i
		btn.pressed.connect(func(): _upgrade(idx))
		hbox.add_child(btn)
		stat_btns.append(btn)

	vbox.add_child(HSeparator.new())

	var close_lbl = Label.new()
	close_lbl.text = "[TAB] Cerrar"
	close_lbl.add_theme_font_size_override("font_size", 12)
	close_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(close_lbl)

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

func _upgrade(idx: int) -> void:
	if not player:
		return
	var s    = STATS[idx]
	var cost = idx + 1
	if player.stat_points < cost:
		return
	player.stat_points -= cost
	match s["key"]:
		"Vitalidad":
			player.max_hp = player.max_hp + 25
			player.hp     = min(player.hp + 25, player.max_hp)
			player.emit_signal("health_changed", player.hp, player.max_hp)
		_:
			player.set(s["var"], player.get(s["var"]) + s["inc"])
	_refresh()

func _refresh() -> void:
	if not player:
		return
	points_lbl.text = "Puntos disponibles: %d" % player.stat_points
	var vals = [
		player.base_damage,
		player.max_hp,
		player.move_speed,
		player.max_mana,
	]
	for i in range(STATS.size()):
		var s    = STATS[i]
		var cost = i + 1
		stat_labels[i].text = "%s: %s" % [s["label"], str(vals[i])]
		stat_btns[i].text   = "+ (%d pts)" % cost
		stat_btns[i].disabled = player.stat_points < cost
