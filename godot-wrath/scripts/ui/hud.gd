extends CanvasLayer

var hp_bar     : ProgressBar
var mana_bar   : ProgressBar
var hp_label   : Label
var mana_label : Label
var wave_label : Label
var kills_label: Label
var level_label: Label
var gold_label : Label
var msg_label  : Label
var msg_timer  : float = 0.0
var kill_count : int   = 0

# Spell cooldown labels
var cd_labels        : Dictionary = {}
var slot_name_labels : Array = []
var slot_cost_labels : Array = []
var player_ref : Node = null

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

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Bottom-left panel: HP and Mana
	var panel = PanelContainer.new()
	panel.anchor_left   = 0.0
	panel.anchor_right  = 0.0
	panel.anchor_top    = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = 10
	panel.offset_top    = -130
	panel.offset_right  = 250
	panel.offset_bottom = -10
	add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	hp_label = Label.new()
	hp_label.text = "HP: 150 / 150"
	vbox.add_child(hp_label)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(220, 18)
	hp_bar.max_value  = 150
	hp_bar.value      = 150
	hp_bar.show_percentage = false
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.8, 0.1, 0.1, 1)
	hp_bar.add_theme_stylebox_override("fill", hp_style)
	vbox.add_child(hp_bar)

	mana_label = Label.new()
	mana_label.text = "MANA: 80 / 80"
	vbox.add_child(mana_label)

	mana_bar = ProgressBar.new()
	mana_bar.custom_minimum_size = Vector2(220, 18)
	mana_bar.max_value  = 80
	mana_bar.value      = 80
	mana_bar.show_percentage = false
	var mana_style = StyleBoxFlat.new()
	mana_style.bg_color = Color(0.1, 0.3, 0.9, 1)
	mana_bar.add_theme_stylebox_override("fill", mana_style)
	vbox.add_child(mana_bar)

	# Top-right panel: stats
	var rpanel = PanelContainer.new()
	rpanel.anchor_left   = 1.0
	rpanel.anchor_right  = 1.0
	rpanel.anchor_top    = 0.0
	rpanel.anchor_bottom = 0.0
	rpanel.offset_left   = -220
	rpanel.offset_top    = 10
	rpanel.offset_right  = -10
	rpanel.offset_bottom = 100
	add_child(rpanel)

	var rvbox = VBoxContainer.new()
	rpanel.add_child(rvbox)

	level_label = Label.new()
	level_label.text = "Level 1"
	rvbox.add_child(level_label)

	gold_label = Label.new()
	gold_label.text = "Gold: 0"
	rvbox.add_child(gold_label)

	kills_label = Label.new()
	kills_label.text = "Kills: 0"
	rvbox.add_child(kills_label)

	# Top-center: wave name
	wave_label = Label.new()
	wave_label.text = "Oleada 1"
	wave_label.anchor_left   = 0.5
	wave_label.anchor_right  = 0.5
	wave_label.anchor_top    = 0.0
	wave_label.anchor_bottom = 0.0
	wave_label.offset_left   = -80
	wave_label.offset_top    = 10
	wave_label.offset_right  = 80
	wave_label.offset_bottom = 40
	wave_label.add_theme_font_size_override("font_size", 24)
	add_child(wave_label)

	# Bottom-center: spell bar
	var spell_panel = PanelContainer.new()
	spell_panel.anchor_left   = 0.5
	spell_panel.anchor_right  = 0.5
	spell_panel.anchor_top    = 1.0
	spell_panel.anchor_bottom = 1.0
	spell_panel.offset_left   = -300
	spell_panel.offset_top    = -90
	spell_panel.offset_right  = 300
	spell_panel.offset_bottom = -10
	add_child(spell_panel)

	var spell_hbox = HBoxContainer.new()
	spell_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	spell_panel.add_child(spell_hbox)

	for i in range(6):
		var vb    = VBoxContainer.new()
		vb.custom_minimum_size = Vector2(90, 60)
		spell_hbox.add_child(vb)

		var key_lbl = Label.new()
		key_lbl.text = ["E","R","Q","1","2","3"][i]
		key_lbl.add_theme_font_size_override("font_size", 10)
		key_lbl.add_theme_color_override("font_color", Color.GRAY)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(key_lbl)

		var name_lbl = Label.new()
		name_lbl.text = "—"
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(name_lbl)
		slot_name_labels.append(name_lbl)

		var cost_lbl = Label.new()
		cost_lbl.text = "— MP"
		cost_lbl.add_theme_font_size_override("font_size", 10)
		cost_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 1))
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(cost_lbl)
		slot_cost_labels.append(cost_lbl)

		var cd_lbl = Label.new()
		cd_lbl.text = "—"
		cd_lbl.add_theme_font_size_override("font_size", 11)
		cd_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(cd_lbl)
		cd_labels[i] = cd_lbl

	# Crosshair
	var crosshair = ColorRect.new()
	crosshair.color = Color(1, 1, 1, 0.85)
	crosshair.size = Vector2(6, 6)
	crosshair.anchor_left   = 0.5
	crosshair.anchor_right  = 0.5
	crosshair.anchor_top    = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left   = -3
	crosshair.offset_right  = 3
	crosshair.offset_top    = -3
	crosshair.offset_bottom = 3
	add_child(crosshair)

	# Center: big message
	msg_label = Label.new()
	msg_label.text = ""
	msg_label.anchor_left   = 0.5
	msg_label.anchor_right  = 0.5
	msg_label.anchor_top    = 0.5
	msg_label.anchor_bottom = 0.5
	msg_label.offset_left   = -150
	msg_label.offset_top    = -20
	msg_label.offset_right  = 150
	msg_label.offset_bottom = 20
	msg_label.add_theme_font_size_override("font_size", 32)
	add_child(msg_label)

func _process(delta: float) -> void:
	if msg_timer > 0:
		msg_timer -= delta
		if msg_timer <= 0:
			msg_label.text = ""

	if not player_ref or not is_instance_valid(player_ref):
		return

	var slots = player_ref.active_slots
	for i in range(6):
		var key  = slots[i] if i < slots.size() else ""
		var name_lbl : Label = slot_name_labels[i]
		var cost_lbl : Label = slot_cost_labels[i]
		var cd_lbl   : Label = cd_labels[i]

		if key == "" or not key in ABILITY_DATA:
			name_lbl.text = "—"
			cost_lbl.text = "— MP"
			cd_lbl.text   = "—"
			cd_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
			continue

		var data = ABILITY_DATA[key]
		name_lbl.text = data["name"]
		name_lbl.add_theme_color_override("font_color", data["color"])
		cost_lbl.text = "%d MP" % data["mp"]

		var cd : float = player_ref.get_ability_cd(key)
		if cd > 0:
			cd_lbl.text = "%.1fs" % cd
			cd_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2, 1))
		else:
			cd_lbl.text = "Listo"
			cd_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4, 1))

func connect_player(player: Node) -> void:
	if not player:
		return
	player_ref = player
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_hp_changed)
	if player.has_signal("mana_changed"):
		player.mana_changed.connect(_on_mana_changed)
	if player.has_signal("level_up"):
		player.level_up.connect(_on_level_up)
	if player.has_signal("enemy_killed"):
		player.enemy_killed.connect(_on_kill)
	_on_hp_changed(player.hp, player.max_hp)
	_on_mana_changed(int(player.mana), player.max_mana)

func _on_hp_changed(cur: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value     = cur
	hp_label.text    = "HP: %d / %d" % [cur, maximum]

func _on_mana_changed(cur: int, maximum: int) -> void:
	mana_bar.max_value = maximum
	mana_bar.value     = cur
	mana_label.text    = "MANA: %d / %d" % [cur, maximum]

func _on_level_up(new_level: int) -> void:
	level_label.text = "Level %d" % new_level
	show_message("LEVEL UP!", Color.YELLOW)

func _on_kill() -> void:
	kill_count += 1
	kills_label.text = "Kills: %d" % kill_count

func show_message(text: String, color: Color = Color.WHITE) -> void:
	msg_label.text = text
	msg_label.add_theme_color_override("font_color", color)
	msg_timer = 2.5

func update_wave(wave_num: int) -> void:
	wave_label.text = "Oleada %d" % wave_num

func update_gold(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount
