extends Node2D

onready var enemy = preload("res://Entities/Enemy/enemy.tscn")
onready var enemy_physical = preload("res://Entities/Enemy/EnemyPhysical.tscn")
onready var ship = preload("res://Entities/Ship/Ship.tscn")
onready var menu = preload("res://Menu/Menu.tscn")
onready var game_layer = get_node("Game_CanvasLayer")
onready var enemies_group = get_node("Game_CanvasLayer/Enemies")
onready var game_timer = get_node("GameTimer")
onready var HUD = get_node("HUD")

var current_level = 1
const max_level = 4

var menu_displayed = null
var current_ship = null

func end_level(won):
	if menu_displayed:
		return
	# no pause:
	#get_tree().set_pause(true)
	if won == false or current_level >= max_level:
		set_process_input(false)
		menu_displayed = menu.instance()
		menu_displayed.mode = menu_displayed.game_over
		add_child(menu_displayed)
		menu_displayed.raise()
	else:
		current_level += 1
		init_level()

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
	if can_continue:
		setup_ship()
	else:
		end_level(false)

func setup_ship():
	if current_ship:
		current_ship.queue_free()
		current_ship = null
	current_ship = ship.instance()
	if current_level in [1, 2]:
		current_ship.ammo_type_ = 0
		current_ship.ammo_count_ = 9999
	elif current_level == 3:
		current_ship.ammo_type_ = 1
		current_ship.ammo_count_ = 10
	elif current_level == 4:
		current_ship.ammo_type_ = 0
		current_ship.ammo_count_ = 0
	current_ship.set_global_pos(Vector2(512, 300)) # TODO replace with viewport code
	game_layer.add_child(current_ship)

func init_level():
	HUD.update_level(current_level)
	set_process(true)
	set_process_input(true)

func _ready():
	current_level = 1
	add_life(2)
	setup_ship()
	init_level()

func add_life(num):
	HUD.add_life(num)

func remove_life():
	return HUD.remove_life()

func update_hud(delta):
	var ratio_left = game_timer.get_time_left() / game_timer.get_wait_time()
	HUD.update_timer(ratio_left)
	if current_ship:
		HUD.update_ammo(current_ship.ammo_count_)

func _process(delta):
	if not menu_displayed:
		update_hud(delta)
	# end game: no more enemies
	var enemies_in_scene = enemies_group.get_child_count()
	for e in enemies_group.get_children():
		if e.is_dead():
			enemies_in_scene -= 1
	if enemies_in_scene == 0:
		end_level(true)
	# end game: time's up
	if game_timer.get_time_left() <= 0.0:
		end_level(false)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		pause()