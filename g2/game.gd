extends Node2D

onready var enemy = preload("res://Entities/Enemy/enemy.tscn")
onready var ship = preload("res://Entities/Ship/Ship.tscn")
onready var menu = preload("res://Menu/Menu.tscn")
onready var game_layer = get_node("Game_CanvasLayer")
onready var enemies_group = get_node("Game_CanvasLayer/Enemies")
onready var game_timer = get_node("GameTimer")

var enemies = []

func end_game(won):
	# no pause:
	#get_tree().set_pause(true)
	set_process_input(false)
	var new_menu = menu.instance()
	if won:
		new_menu.mode = new_menu.win
	else:
		new_menu.mode = new_menu.game_over
	add_child(new_menu)
	new_menu.raise()

func pause():
	get_tree().set_pause(true)
	set_process_input(false)
	var new_menu = menu.instance()
	new_menu.mode = new_menu.pause
	add_child(new_menu)
	new_menu.raise()

func unpause(menu_instance):
	remove_child(menu_instance)
	set_process_input(true)
	get_tree().set_pause(false)

func ship_destroyed():
	var can_continue = remove_life()
	if not can_continue:
		end_game(false)

func setup_ship():
	var new_ship = ship.instance()
	new_ship.set_global_pos(Vector2(512, 300))
	game_layer.add_child(new_ship)

func _ready():
	setup_hud()
	setup_bots()
	setup_ship()
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
		var e = enemy.instance()
		enemies_group.add_child(e)

func update_hud(delta):
	var prog = get_node("HUD_CanvasLayer/HUD/TimeLeft")
	var left_ratio = game_timer.get_time_left() / game_timer.get_wait_time()
	prog.set_value(prog.get_max() * left_ratio)

func _process(delta):
	update_hud(delta)
	# end game: no more enemies
	var enemies_in_scene = enemies_group.get_child_count()
	for e in enemies_group.get_children():
		if e.is_dead():
			enemies_in_scene -= 1
	if enemies_in_scene == 0:
		end_game(true)
	# end game: time's up
	if game_timer.get_time_left() <= 0.0:
		end_game(false)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		pause()