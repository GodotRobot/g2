extends Node2D

onready var enemy = preload("res://Entities/Enemy/enemy.tscn")
onready var menu = preload("res://Menu/Menu.tscn")
onready var game_layer = get_node("Game_CanvasLayer")
onready var game_timer = get_node("GameTimer")

func end_game():
	print("game ended TODO")
	pass

func pause():
	get_tree().set_pause(true)
	set_process_input(false)
	var new_menu = menu.instance()
	new_menu.pause_menu = true
	add_child(new_menu)
	new_menu.raise()

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
	var prog = get_node("HUD_CanvasLayer/HUD/TimeLeft")
	var left_ratio = game_timer.get_time_left() / game_timer.get_wait_time()
	prog.set_value(prog.get_max() * left_ratio)

func _process(delta):
	update_hud(delta)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		pause()