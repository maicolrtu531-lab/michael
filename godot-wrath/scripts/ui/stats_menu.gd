extends CanvasLayer

@onready var panel       : Panel    = $Panel
@onready var points_lbl  : Label    = $Panel/PointsLabel
@onready var str_lbl     : Label    = $Panel/StrRow/ValueLabel
@onready var vit_lbl     : Label    = $Panel/VitRow/ValueLabel
@onready var agi_lbl     : Label    = $Panel/AgiRow/ValueLabel
@onready var int_lbl     : Label    = $Panel/IntRow/ValueLabel
@onready var str_cost    : Label    = $Panel/StrRow/CostLabel
@onready var vit_cost    : Label    = $Panel/VitRow/CostLabel
@onready var agi_cost    : Label    = $Panel/AgiRow/CostLabel
@onready var int_cost    : Label    = $Panel/IntRow/CostLabel

var player    : Node   = null
var selected  : int    = 0
var stat_keys : Array  = ["Fuerza", "Vitalidad", "Agilidad", "Inteligencia"]

func _ready() -> void:
	panel.visible = false

func connect_player(p: Node) -> void:
	player = p

func toggle() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		_refresh()

func _input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("ui_up"):
		selected = (selected - 1 + stat_keys.size()) % stat_keys.size()
		_refresh()
	elif event.is_action_pressed("ui_down"):
		selected = (selected + 1) % stat_keys.size()
		_refresh()
	elif event.is_action_pressed("ui_accept"):
		_upgrade_selected()
	elif event.is_action_pressed("ui_cancel"):
		panel.visible = false

func _upgrade_selected() -> void:
	if not player:
		return
	var key       = stat_keys[selected]
	var cur_level = player.stats[key]
	var cost      = cur_level  # cost = current level in that stat

	if player.stat_points < cost:
		return

	player.stat_points  -= cost
	player.stats[key]   += 1

	match key:
		"Fuerza":       player.base_damage += 4
		"Vitalidad":
			player.max_hp += 25
			player.hp      = min(player.hp + 25, player.max_hp)
		"Agilidad":     player.move_speed  += 0.6
		"Inteligencia": player.max_mana    += 12
	_refresh()

func _refresh() -> void:
	if not player:
		return
	points_lbl.text = "Puntos disponibles: %d" % player.stat_points
	var labels = [str_lbl, vit_lbl, agi_lbl, int_lbl]
	var costs  = [str_cost, vit_cost, agi_cost, int_cost]
	for i in range(stat_keys.size()):
		var key = stat_keys[i]
		var cur = player.stats[key]
		labels[i].text = "%s: %d" % [key, cur]
		costs[i].text  = "(costo: %d pts)" % cur
		# Highlight selected
		var color = Color.GOLD if i == selected else Color.WHITE
		labels[i].modulate = color
		costs[i].modulate  = color
