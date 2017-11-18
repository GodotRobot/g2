# http://docs.godotengine.org/en/stable/learning/step_by_step/singletons_autoload.html

# GameManager is the only true god. Handles all game state changes:
# pause /  hud / nwe ships / level changes / game over / options

extends Node

# levels and entities
const LEVEL_BASE = preload("res://Levels/LevelBase.gd")
const MENU = preload("res://Menu/Menu.tscn")
const MENU_BASE = preload("res://Menu/Menu.gd")
const LEVEL_PATH = "res://Levels/Level<N>.tscn"
const SHIP = preload("res://Entities/Ship/Ship.tscn")

# game consts
const INITIAL_LIVES = 2

var ship_pos_on_level_end
var ship_rot_on_level_end

var current_scene = null
var cur_level = 1
var lives = INITIAL_LIVES
var paused = false

# debug prints. replace the print() with pass to disabled logging
func dbg(msg):
	#print(msg)
	pass

func level_ready(level):
	assert(level == current_scene)
	var hud = current_scene.get_hud()
	if hud:
		hud.set_lifes(lives)

func ship_destroyed(instance):
	dbg("ship " + instance.get_name() + " destoryed!")
	lives -= 1
	if lives > 0:
		var new_ship = SHIP.instance();
		new_ship.set_pos(instance.get_pos())
		new_ship.set_rot(instance.get_rot())
		instance.get_parent().add_child(new_ship) # old ship will be deleted once its death animation ends
	else:
		game_over()
	var hud = current_scene.get_hud()
	if hud:
		hud.remove_life(1)

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child( root.get_child_count() -1 )
	set_process(true)
	set_process_input(true)

func get_current_ship():
	var ships = get_tree().get_nodes_in_group("ship")
	if ships.empty():
		dbg("get_current_ship() is not implemented for " + String(ships.size()) + " ships")
	else:
		return ships.back()
	return null

func game_over():
	dbg("game over!")
	var menu_displayed = MENU.instance()
	menu_displayed.mode = menu_displayed.game_over
	current_scene.add_child(menu_displayed)
	menu_displayed.raise()

func start_game():
	lives = INITIAL_LIVES
	goto_scene(LEVEL_PATH.replace("<N>", "1"))

func quit_game():
	get_tree().quit()

func pause():
	if current_scene extends MENU_BASE:
		return
	get_tree().set_pause(true)
	set_process_input(false)
	var menu_displayed = MENU.instance()
	menu_displayed.mode = menu_displayed.pause
	current_scene.add_child(menu_displayed)
	menu_displayed.raise()

func unpause(pause_menu_instance):
	current_scene.remove_child(pause_menu_instance)
	set_process_input(true)
	get_tree().set_pause(false)

func _process(delta):
	if not (current_scene extends LEVEL_BASE):
		return # do nothing for menu level
	if current_scene.level_won():
		dbg("level " + String(cur_level) + " won!")
		var cur_ship = get_current_ship()
		assert(cur_ship)
		ship_pos_on_level_end = cur_ship.get_pos()
		ship_rot_on_level_end = cur_ship.get_rot()
		cur_level += 1
		goto_scene(LEVEL_PATH.replace("<N>", String(cur_level)))
	if current_scene.level_lost():
		print("todo")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		pause()

func goto_scene(path):
	# This function will usually be called from a signal callback,
	# or some other function from the running scene.
	# Deleting the current scene at this point might be
	# a bad idea, because it may be inside of a callback or function of it.
	# The worst case will be a crash or unexpected behavior.
	# The way around this is deferring the load to a later time, when
	# it is ensured that no code from the current scene is running:
	call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(path):
	# Immediately free the current scene,
	# there is no risk here.
	current_scene.free()
	# Load new scene
	var s = ResourceLoader.load(path)
	assert(s != null) # LD: next level not found?! FIXME
	# Instance the new scene
	current_scene = s.instance()
	# Add it to the active scene, as child of root
	get_tree().get_root().add_child(current_scene)
	# optional, to make it compatible with the SceneTree.change_scene() API
	get_tree().set_current_scene( current_scene )