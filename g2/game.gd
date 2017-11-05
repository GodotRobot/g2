extends Node2D

onready var enemy = preload("res://Entities/Enemy/enemy.tscn")
onready var ship = preload("res://Entities/Ship/Ship.tscn")
onready var menu = preload("res://Menu/Menu.tscn")
onready var game_layer = get_node("Game_CanvasLayer")
onready var enemies_group = get_node("Game_CanvasLayer/Enemies")
onready var game_timer = get_node("GameTimer")

var menu_displayed = null

func end_game(won):
	if menu_displayed:
		return
	# no pause:
	#get_tree().set_pause(true)
	set_process_input(false)
	menu_displayed = menu.instance()
	if won:
		menu_displayed.mode = menu_displayed.win
	else:
		menu_displayed.mode = menu_displayed.game_over
	add_child(menu_displayed)
	menu_displayed.raise()

func pause():
	get_tree().set_pause(true)
	set_process_input(false)
	menu_displayed = menu.instance()
	menu_displayed.mode = menu_displayed.pause
	add_child(menu_displayed)
	menu_displayed.raise()

func unpause(menu_instance):
	remove_child(menu_instance)
	assert menu_displayed == menu_instance
	menu_displayed = null
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
	get_node("HUD_CanvasLayer/HUD/LivesLeft").add_child(get_node("HUD_CanvasLayer/HUD/LivesLeft/Life").duplicate()) # icon
	get_node("HUD_CanvasLayer/HUD/LivesLeft").add_child(get_node("HUD_CanvasLayer/HUD/LivesLeft/Sep").duplicate()) # separator

func remove_life():
	var lives_container = get_node("HUD_CanvasLayer/HUD/LivesLeft")
	var children = lives_container.get_children()
	if children.empty():
		return false
	lives_container.remove_child(children[children.size()-1]) # icon
	lives_container.remove_child(children[children.size()-2]) # separator
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