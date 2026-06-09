extends CanvasLayer

@onready var hp_bar       : ProgressBar = $Panel/HPBar
@onready var mana_bar     : ProgressBar = $Panel/ManaBar
@onready var exp_bar      : ProgressBar = $Panel/EXPBar
@onready var hp_label     : Label       = $Panel/HPBar/Label
@onready var mana_label   : Label       = $Panel/ManaBar/Label
@onready var level_label  : Label       = $Panel/LevelLabel
@onready var kills_label  : Label       = $Panel/KillsLabel
@onready var gold_label   : Label       = $Panel/GoldLabel
@onready var potions_label: Label       = $Panel/PotionsLabel
@onready var boss_bar_panel : Control   = $BossBar
@onready var boss_hp_bar  : ProgressBar = $BossBar/HPBar
@onready var boss_name_lbl: Label       = $BossBar/NameLabel
@onready var level_up_lbl : Label       = $LevelUpLabel
@onready var stat_hint    : Label       = $StatHintLabel
@onready var lock_indicator : Control  = $LockIndicator
@onready var crosshair    : TextureRect = $Crosshair

var player : Node = null
var blink_t : float = 0.0

func _ready() -> void:
	boss_bar_panel.visible = false
	level_up_lbl.visible   = false
	level_up_lbl.modulate.a = 0.0

func connect_player(p: Node) -> void:
	player = p
	p.health_changed.connect(_on_health_changed)
	p.mana_changed.connect(_on_mana_changed)
	p.level_up.connect(_on_level_up)
	_refresh_all()

func _process(delta: float) -> void:
	blink_t += delta
	if player:
		_update_exp()
		_update_labels()
		_update_stat_hint()
		_update_lock_indicator()

func _refresh_all() -> void:
	if not player:
		return
	_on_health_changed(player.hp, player.max_hp)
	_on_mana_changed(int(player.mana), player.max_mana)

func _on_health_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value     = current
	hp_label.text    = "%d / %d" % [current, maximum]

func _on_mana_changed(current: int, maximum: int) -> void:
	mana_bar.max_value = maximum
	mana_bar.value     = current
	mana_label.text    = "%d / %d" % [current, maximum]

func _update_exp() -> void:
	exp_bar.max_value = player.exp_needed()
	exp_bar.value     = player.exp

func _update_labels() -> void:
	level_label.text   = "Nv. %d" % player.level
	kills_label.text   = "☠ %d" % player.kills
	gold_label.text    = "🪙 %d" % player.gold
	potions_label.text = "🧪 %d" % player.potions

func _update_stat_hint() -> void:
	if player.stat_points > 0:
		stat_hint.visible = true
		stat_hint.modulate.a = 0.5 + 0.5 * sin(blink_t * 4.0)
		stat_hint.text = "M — %d puntos de estadística disponibles" % player.stat_points
	else:
		stat_hint.visible = false

func _update_lock_indicator() -> void:
	if not player.locked_target or not is_instance_valid(player.locked_target):
		lock_indicator.visible = false
		return
	lock_indicator.visible = true
	var cam = get_viewport().get_camera_3d()
	if cam:
		var screen_pos = cam.unproject_position(player.locked_target.global_position)
		lock_indicator.global_position = screen_pos - lock_indicator.size / 2

func show_boss(boss_node: Node) -> void:
	boss_bar_panel.visible = true
	boss_name_lbl.text     = boss_node.enemy_name
	boss_node.died.connect(_on_boss_died)
	# Update boss bar each frame via timer
	var t = Timer.new()
	add_child(t)
	t.wait_time = 0.05
	t.timeout.connect(func():
		if is_instance_valid(boss_node):
			boss_hp_bar.max_value = boss_node.max_hp
			boss_hp_bar.value     = boss_node.hp
		else:
			t.queue_free()
	)
	t.autostart = true

func _on_boss_died(_b) -> void:
	boss_bar_panel.visible = false

func _on_level_up(new_level: int) -> void:
	level_up_lbl.text    = "¡NIVEL %d!" % new_level
	level_up_lbl.visible = true
	var tween = create_tween()
	tween.tween_property(level_up_lbl, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.2)
	tween.tween_property(level_up_lbl, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): level_up_lbl.visible = false)
