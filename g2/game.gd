extends Node2D

onready var enemy = preload("res://Entities/Enemy/enemy.tscn")
onready var enemy_physical = preload("res://Entities/Enemy/EnemyPhysical.tscn")
onready var ship = preload("res://Entities/Ship/Ship.tscn")
onready var menu = preload("res://Menu/Menu.tscn")
onready var game_layer = get_node("Game_CanvasLayer")
onready var enemies_group = get_node("Game_CanvasLayer/Enemies")
onready var game_timer = get_node("GameTimer")
onready var level_text = get_node("HUD_CanvasLayer/HUD/Level")
onready var ammo_text = get_node("HUD_CanvasLayer/HUD/Ammo")

var current_level = 1
const max_level = 4

var LEVEL_NAME = ['kill', 'kill', 'bounce', 'survive']

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
		level_text.hide()
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
	level_text.set_text("Level " + String(current_level) + ": " + LEVEL_NAME[current_level-1])
	level_text.show()
	setup_bots()
	set_process(true)
	set_process_input(true)

func _ready():
	current_level = 1
	add_life(2)
	setup_ship()
	init_level()

func add_life(num):
	for i in range(num - 1):
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

func setup_bots():
	# defaults
	var count = 2
	var behavior = 0
	var bot_class = enemy
	# level-based enemy defs.
	if current_level == 1:
		count = 4
	elif current_level == 2:
		count = 8
	elif current_level == 3:
		count = 2
		bot_class = enemy_physical
	elif current_level == 4:
		count = 40
		bot_class = enemy
		behavior = 1
	# create
	for i in range(0, count):
		var e = bot_class.instance()
		e.set_behavior(behavior)
		enemies_group.add_child(e)

func update_hud(delta):
	var prog = get_node("HUD_CanvasLayer/HUD/TimeLeft")
	var left_ratio = game_timer.get_time_left() / game_timer.get_wait_time()
	prog.set_value(prog.get_max() * left_ratio)
	if current_ship:
		ammo_text.set_text(String(current_ship.ammo_count_))

func _process(delta):
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