extends Node2D

var max_time_ms = 60000.0

func end_game():
	pass

func death():
	var can_continue = remove_life()
	if not can_continue:
		end_game()

func _ready():
	setup_hud()
	setup_bots()
	set_process(true)

func add_life():
	get_node("HUD_CanvasLayer/HUD/LivesLeft").add_child(get_node("HUD_CanvasLayer/HUD/LivesLeft/Life").duplicate())
	get_node("HUD_CanvasLayer/HUD/LivesLeft").add_child(get_node("HUD_CanvasLayer/HUD/LivesLeft/Sep").duplicate())

func remove_life():
	var lives_container = get_node("HUD_CanvasLayer/HUD/LivesLeft")
	var children = lives_container.get_children()
	if children.empty():
		return false
	lives_container.remove_child(children[children.size()-1])
	lives_container.remove_child(children[children.size()-2])
	return true

func setup_hud():
	add_life()
	add_life()

func setup_bots():
	var enemy = preload("res://Entities/Enemy/enemy.tscn")
	get_node("Game_CanvasLayer").add_child(enemy.instance())
	get_node("Game_CanvasLayer").add_child(enemy.instance())
	get_node("Game_CanvasLayer").add_child(enemy.instance())
	get_node("Game_CanvasLayer").add_child(enemy.instance())
	get_node("Game_CanvasLayer").add_child(enemy.instance())

func update_hud(delta):
	var elapsed_msec = OS.get_ticks_msec()
	var elapsed_per = elapsed_msec / max_time_ms
	get_node("HUD_CanvasLayer/HUD/TimeLeft").set_value(1000.0 * (1.0 - elapsed_per))

func _process(delta):
	update_hud(delta)