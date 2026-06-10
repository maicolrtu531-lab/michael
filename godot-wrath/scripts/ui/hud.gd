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
var cd_labels  : Dictionary = {}
var player_ref : Node = null

# Spell metadata: key -> [display_name, cd_var, mana_cost, color]
const SPELLS = {
	"axe":       ["E  Hacha",       "axe_cd",       15, Color(1.0, 0.7, 0.2, 1)],
	"blizzard":  ["R  Blizzard",    "blizzard_cd",  25, Color(0.4, 0.8, 1.0, 1)],
	"rage":      ["Q  Furia",       "rage_cd",      30, Color(1.0, 0.3, 0.0, 1)],
	"lightning": ["1  Rayo",        "lightning_cd", 20, Color(1.0, 1.0, 0.3, 1)],
	"shield":    ["2  Escudo Div.", "shield_cd",    20, Color(0.3, 0.6, 1.0, 1)],
	"slam":      ["3  Terremoto",   "slam_cd",      30, Color(0.9, 0.5, 0.1, 1)],
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

	for key in ["axe", "blizzard", "rage", "lightning", "shield", "slam"]:
		var data  = SPELLS[key]
		var vb    = VBoxContainer.new()
		vb.custom_minimum_size = Vector2(90, 60)
		spell_hbox.add_child(vb)

		var name_lbl = Label.new()
		name_lbl.text = data[0]
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", data[3])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(name_lbl)

		var cost_lbl = Label.new()
		cost_lbl.text = "%d MP" % data[2]
		cost_lbl.add_theme_font_size_override("font_size", 10)
		cost_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 1))
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(cost_lbl)

		var cd_lbl = Label.new()
		cd_lbl.text = "Listo"
		cd_lbl.add_theme_font_size_override("font_size", 11)
		cd_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4, 1))
		cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(cd_lbl)
		cd_labels[key] = cd_lbl

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

	var cd_map = {
		"axe":       player_ref.axe_cd,
		"blizzard":  player_ref.blizzard_cd,
		"rage":      player_ref.rage_cd,
		"lightning": player_ref.lightning_cd,
		"shield":    player_ref.shield_cd,
		"slam":      player_ref.slam_cd,
	}
	for key in cd_map:
		var lbl : Label = cd_labels[key]
		var cd  : float = cd_map[key]
		if cd > 0:
			lbl.text = "%.1fs" % cd
			lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2, 1))
		else:
			lbl.text = "Listo"
			lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4, 1))

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
