extends Node2D

onready var enemy = preload("res://Entities/Enemy/enemy.tscn")
onready var menu = preload("res://Menu/Menu.tscn")
onready var game_layer = get_node("Game_CanvasLayer")

var max_time_ms = 60000.0

func end_game():
	print("game ended")
	pass

func pause():
	get_tree().set_pause(true)
	set_process_input(false)
	add_child(menu.instance())

func unpause(menu_instance):
	remove_child(menu_instance)
	set_process_input(true)
	get_tree().set_pause(false)

func death():
	var can_continue = remove_life()
	if not can_continue:
		end_game()

func _ready():
	setup_hud()
	setup_bots()
	set_process(true)
	set_process_input(true)

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
	for i in range(0, 5):
		game_layer.add_child(enemy.instance())

func update_hud(delta):
	var elapsed_msec = OS.get_ticks_msec()
	var elapsed_per = elapsed_msec / max_time_ms
	get_node("HUD_CanvasLayer/HUD/TimeLeft").set_value(1000.0 * (1.0 - elapsed_per))

func _process(delta):
	update_hud(delta)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		pause()