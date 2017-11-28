# http://docs.godotengine.org/en/stable/learning/step_by_step/singletons_autoload.html

# GameManager is the only true god. Handles all game state changes:
# pause /  hud / nwe ships / level changes / game over / options

extends Node

# levels and entities
const LEVEL_BASE = preload("res://Levels/LevelBase.gd")
const COLLECTABLE_BASE = preload("res://Entities/Collectables/CollectableBase.gd")
const MENU = preload("res://Menu/Menu.tscn")
const MENU_BASE = preload("res://Menu/Menu.gd")
const LEVEL_PATH = "res://Levels/Level<N>.tscn"
const SHIP = preload("res://Entities/Ship/Ship.tscn")
const HTTP = preload("res://Menu/HTTP.gd")

################### game consts and balance ##########################
# initial ships upon starting the game
const INITIAL_LIVES = 3
const MAX_LIFE = 5
# time to wait between killing the last enemy in the level and going to the next one
const LEVEL_POST_MORTEM_DELAY_SEC = 1.0
# bullet speed is contant, so make sure the shooter is never faster than it
const BULLET_SPEED = 700
# initial warp drive charges
const INITIAL_WARP = 10
const MAX_WARP = 21
# make bullet start ahead of ship. also eliminate visible delay when shooting while rotating
const BULLET_AHEAD = 40
# ship movement parameters - set linear/angular acceleration to 0 if you want to restore non-physical movement
const SHIP_ACCELERATION = 0#10.0
const SHIP_DRAG = 0.92
const SHIP_MAX_SPEED = 400.0
const SHIP_ANGULAR_ACCELERATION = 0#9.0
const SHIP_ANGULAR_DRAG = 0.92
const SHIP_MAX_ANGULAR_SPEED = 10.0
######################################################################

var ship_pos_on_level_end
var ship_rot_on_level_end

# singletons
var http

var current_scene = null
var cur_level = 1
var lives = INITIAL_LIVES
var cur_warp = INITIAL_WARP
var paused = false
var debug = true
var score = 0
var warp_remaining = 5
var warp_to_start_level = true

func dbg(msg):
	if debug:
		print(msg)

func level_ready(level):
	assert(level == current_scene)
	var hud = current_scene.get_hud()
	if hud:
		hud.set_lives(lives)
		hud.set_score(score)
		hud.set_warps(cur_warp)
		hud.set_level(cur_level)
		hud.get_node("HUD/CkbxDebug").set_pressed(debug)

func collectable_collected(collectable, who):
	dbg(collectable.get_name() + " was hit by " + who.get_name())
	if collectable.health > 0:
		dbg("additional health: " + String(collectable.health))
		add_life()
	if collectable.warp > 0:
		dbg("additional warp: " + String(collectable.warp))
		add_warp()
	if collectable.shield > 0:
		dbg("additional shield: " + String(collectable.shield))
		get_current_ship().add_shield(collectable.shield)
	if collectable.boom > 0:
		dbg("collected boom: " + String(collectable.boom))
		# kill all enemies
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			e.start_death()

func ship_warped():
	if cur_warp > 0:
		cur_warp -= 1
	current_scene.get_hud().remove_warps(1)

func add_life():
	if lives < MAX_LIFE:
		lives += 1
		var hud = current_scene.get_hud()
		if hud:
			hud.add_life(1)

func add_warp():
	if cur_warp < MAX_WARP:
		cur_warp += 1
		var hud = current_scene.get_hud()
		if hud:
			hud.set_warps(cur_warp)

func ship_destroyed(instance):
	dbg("ship " + instance.get_name() + " destoryed!")
	var hud = current_scene.get_hud()
	lives -= 1
	if lives > 0:
		var new_ship = instance.clone(SHIP.instance())
		new_ship.set_pos(current_scene.initial_pos)
		new_ship.set_rot(current_scene.initial_rot)
		warp_to_start_level = true
		cur_warp = INITIAL_WARP
		if hud:
			hud.set_warps(cur_warp)
		instance.get_parent().add_child(new_ship) # old ship will be (self-)deleted once its death animation ends
	else:
		game_over()
		
	if hud:
		hud.remove_life(1)

func enemy_destroyed(instance):
	score += 1
	var hud = current_scene.get_hud()
	if hud:
		hud.set_score(score)
	dbg("enemy " + instance.get_name() + " destoryed!")
	if instance.drop_type:
		dbg("enemy " + instance.get_name() + " had drop type " + String(instance.drop_type))
		var collectable = COLLECTABLE_BASE.factory(instance.drop_type, instance.drop_value)
		if collectable:
			dbg("collectable " + String(instance.drop_type) + "/" + String(instance.drop_value) + " was created")
			collectable.set_pos(instance.get_pos())
			instance.get_parent().add_child(collectable)

func download_highscores(update = null):
	var menu = get_tree().get_nodes_in_group("menu")
	if not menu.empty():
		menu[0].highscores_download_started()
	if update != null:
		http.post("http://warpgamehighscores.azurewebsites.net","/",80,false, update) #domain,url,port,useSSL, post
	else:
		http.get("http://warpgamehighscores.azurewebsites.net","/",80,false) #domain,url,port,useSSL

func highscores_loaded(code,result):
	var menu = get_tree().get_nodes_in_group("menu")
	if not menu.empty():
		var result_string = result.get_string_from_ascii()
		if code != 200:
			dbg("code: " + str(code) + " str: " + result_string)
			result_string = null
		menu[0].update_highscores(result_string)

func set_singletons():
	http = HTTP.new()
	#http.connect("loading",self,"_on_loading")
	http.connect("loaded",self,"highscores_loaded")
	download_highscores()

func _ready():
	# discover initial scene
	var root = get_tree().get_root()
	current_scene = root.get_child( root.get_child_count() -1 )
	# set singletons
	set_singletons()
	# ready set go
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
	if current_scene extends LEVEL_BASE:
		current_scene.on_game_over()
	var menu_displayed = MENU.instance()
	menu_displayed.mode = menu_displayed.game_over
	current_scene.add_child(menu_displayed)
	menu_displayed.raise()

func start_game():
	cur_level = 1
	lives = INITIAL_LIVES
	cur_warp = INITIAL_WARP
	score = 0
	goto_scene(LEVEL_PATH.replace("<N>", "1"))
	warp_to_start_level = true

func quit_game():
	get_tree().quit()

func pause():
	if current_scene extends MENU_BASE:
		return
	if not get_tree().get_nodes_in_group("menu").empty():
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
	if current_scene.level_won() and !get_node("/root/TransitionScreen/AnimationPlayer").is_playing():
		dbg("level " + String(cur_level) + " won!")
		var cur_ship = get_current_ship()
		assert(cur_ship)
		ship_pos_on_level_end = cur_ship.get_pos()
		ship_rot_on_level_end = cur_ship.get_rot()
		transition_to_level(cur_level + 1)
	if current_scene.level_lost():
		print("todo")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		pause()

var titles = ["null", "prepare to die", "this is easy", "who are you?", "idan did it", "sbx4ever", "show me what you got"]

func transition_to_level(next_level):
	cur_level = next_level
	var transition = get_node("/root/TransitionScreen")
	var title = "null"
	if next_level < titles.size():
		title = titles[next_level]
	transition.init(next_level, title)
	transition.get_node("AnimationPlayer").play("Anim")

func goto_level(level):
	goto_scene(LEVEL_PATH.replace("<N>", String(level)))
	
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
	if not s:
		# level not found - for now assume this is WIN
		current_scene = MENU.instance()
		current_scene.mode = current_scene.win
		get_tree().get_root().add_child(current_scene)
		get_tree().set_current_scene( current_scene )
		return

	# Instance the new scene
	current_scene = s.instance()
	# Add it to the active scene, as child of root
	get_tree().get_root().add_child(current_scene)
	# optional, to make it compatible with the SceneTree.change_scene() API
	get_tree().set_current_scene( current_scene )
	
	# make sure level is named properly (root node in levelN.tscn must be "LevelN")
	var level_name = current_scene.get_name()
	var expeced_level_name = "Level" + String(cur_level)
	assert(level_name == expeced_level_name)
	
	
	# reset warp counter for a new level
	current_scene.get_hud().set_warps(cur_warp)

	
