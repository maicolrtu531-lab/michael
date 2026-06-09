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

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(10, -130)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(230, 0)
	panel.add_child(vbox)

	hp_label = Label.new()
	hp_label.text = "HP: 150 / 150"
	vbox.add_child(hp_label)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(210, 18)
	hp_bar.max_value = 150
	hp_bar.value = 150
	hp_bar.show_percentage = false
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.8, 0.1, 0.1, 1)
	hp_bar.add_theme_stylebox_override("fill", hp_style)
	vbox.add_child(hp_bar)

	mana_label = Label.new()
	mana_label.text = "MANA: 80 / 80"
	vbox.add_child(mana_label)

	mana_bar = ProgressBar.new()
	mana_bar.custom_minimum_size = Vector2(210, 18)
	mana_bar.max_value = 80
	mana_bar.value = 80
	mana_bar.show_percentage = false
	var mana_style = StyleBoxFlat.new()
	mana_style.bg_color = Color(0.1, 0.3, 0.9, 1)
	mana_bar.add_theme_stylebox_override("fill", mana_style)
	vbox.add_child(mana_bar)

	var top_right = PanelContainer.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.position = Vector2(-220, 10)
	add_child(top_right)

	var tvbox = VBoxContainer.new()
	tvbox.custom_minimum_size = Vector2(200, 0)
	top_right.add_child(tvbox)

	level_label = Label.new()
	level_label.text = "Level 1"
	tvbox.add_child(level_label)

	gold_label = Label.new()
	gold_label.text = "Gold: 0"
	tvbox.add_child(gold_label)

	kills_label = Label.new()
	kills_label.text = "Kills: 0"
	tvbox.add_child(kills_label)

	wave_label = Label.new()
	wave_label.text = "Wave 1"
	wave_label.set_anchors_preset(Control.PRESET_TOP_CENTER)
	wave_label.position = Vector2(-50, 10)
	wave_label.add_theme_font_size_override("font_size", 24)
	add_child(wave_label)

	var hint = Label.new()
	hint.text = "[LMB] Ataque  [RMB] Pesado  [E] Hacha  [SPACE] Esquivar  [F] Poción  [T] Lock"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_CENTER)
	hint.position = Vector2(-300, -20)
	hint.add_theme_font_size_override("font_size", 11)
	add_child(hint)

	msg_label = Label.new()
	msg_label.text = ""
	msg_label.set_anchors_preset(Control.PRESET_CENTER)
	msg_label.position = Vector2(-100, -20)
	msg_label.add_theme_font_size_override("font_size", 28)
	add_child(msg_label)

func _process(delta: float) -> void:
	if msg_timer > 0:
		msg_timer -= delta
		if msg_timer <= 0:
			msg_label.text = ""

func connect_player(player: Node) -> void:
	if not player:
		return
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
	wave_label.text = "Wave %d" % wave_num

func update_gold(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount
