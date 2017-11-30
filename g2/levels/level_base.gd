extends Node2D

# not "onready" so that we can use it in _enter_tree (can't use it in _init either)
var GameManager

export(String, "shooter", "obstacles") var level_type = "shooter"
export(float, 0.0, 1000.0, 10.0) var level_speed = 90.0

export(Vector2) var initial_pos = Vector2(640.0, 360.0)
export(Vector2) var initial_rot = 0.0

enum LEVEL_TYPE {
	invalid = 0
	shooter = 1
	obstacles = 2
}
var type = LEVEL_TYPE.invalid

const layer0_speed = 10.0
const layer1_speed = 5.0
const layer1_default_speed = 50.0
const layer2_speed = 7.0
const layer2_default_speed = 30.0
const layer3_speed = 3.5

onready var add_time_bonus = false
onready var time_countdown = 30
onready var timer = get_node("LevelCountdown")
onready var time_bonus_label = get_node("TimeBonusLayer/TimeBonusLabel")
onready var time_bonus_timer = get_node("TimeBonusLayer/TimeBonusTimer")

onready var parallax_layer0 = get_node("GameLayer").get_node("ParallaxBackground").get_node("Background0")
onready var parallax_layer1 = get_node("GameLayer").get_node("ParallaxBackground").get_node("Background1")
onready var parallax_layer2 = get_node("GameLayer").get_node("ParallaxBackground").get_node("Background2")
onready var parallax_layer3 = get_node("GameLayer").get_node("ParallaxBackground").get_node("Background3")

func init_type():
	if level_type == "shooter":
		type = LEVEL_TYPE.shooter
	elif level_type == "obstacles":
		type = LEVEL_TYPE.obstacles

func setup():
	if type == LEVEL_TYPE.obstacles:
		var ship = GameManager.get_current_ship()
		ship.set_fake_speed(level_speed)
	elif type == LEVEL_TYPE.shooter:
		var ship = GameManager.get_current_ship()
		assert(ship)
		if GameManager.ship_pos_on_level_end != null:
			ship.set_pos(GameManager.ship_pos_on_level_end)
			ship.set_rot(GameManager.ship_rot_on_level_end)
	GameManager.level_ready(self)
	setup_hud()
	timer.start()

func setup_hud():
	get_hud().set_time(time_countdown)
	var bosses = get_tree().get_nodes_in_group("boss")
	if not bosses.empty():
		assert(bosses.size() == 1)
		get_hud().get_node("HUD/BossHP").show()

func _enter_tree():
	GameManager = get_node("/root/GameManager")
	var v = get_name();
	var h = hash(v)
	GameManager.dbg(v + " starting with seed " + String(h))
	seed(h)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	init_type()
	setup()
	set_process(true)
	if type == LEVEL_TYPE.obstacles:
		var meteors = get_tree().get_nodes_in_group("meteors")
		for m in meteors:
			m.set_fake_speed(level_speed)
		var collectables = get_tree().get_nodes_in_group("collectables")
		for c in collectables:
			c.set_fake_speed(level_speed)

func _process(delta):
	update_hud()
	var ship = GameManager.get_current_ship()
	
	var ship_offset = Vector2(0.0,0.0)
	
	if type == LEVEL_TYPE.shooter:
		# if it's a shooting level, use the ship movement offset to move the parallax layers
		if ship:
			ship_offset = ship.movement_offset
	else:
		# if it's an obstacle level, always move downwards
		ship_offset = Vector2(0.0,-400.0) * delta
	
	var layer0_offset = Vector2(0.0,0.0)
	var layer1_offset = Vector2(0.0,0.0)
	var layer2_offset = Vector2(0.0,0.0)
	var layer3_offset = Vector2(0.0,0.0)
	
	if ship:
		layer0_offset = ship_offset / layer0_speed
		layer1_offset = ship_offset / layer1_speed
		layer2_offset = ship_offset / layer2_speed
		layer3_offset = ship_offset / layer3_speed
		
	# move the stars and clouds layers based on the ship's movement
	parallax_layer0.set_motion_offset(parallax_layer0.get_motion_offset() - layer0_offset)
	parallax_layer3.set_motion_offset(parallax_layer3.get_motion_offset() - layer3_offset)
	
	# move the center asteroids layers
	var asteroids_background_movement0 = Vector2(0.0,0.0)
	var asteroids_background_movement1 = Vector2(0.0,0.0)
	
	if type == LEVEL_TYPE.shooter:
		asteroids_background_movement0 = (Vector2(layer1_default_speed,0) * delta) - layer1_offset
		asteroids_background_movement1 = (Vector2(layer2_default_speed,0) * delta) - layer2_offset
	else:
		asteroids_background_movement0 -= layer1_offset
		asteroids_background_movement1 -= layer2_offset
		
	parallax_layer1.set_motion_offset(parallax_layer1.get_motion_offset() + asteroids_background_movement0)
	parallax_layer2.set_motion_offset(parallax_layer2.get_motion_offset() + asteroids_background_movement1)

func update_hud():
	var bosses = get_tree().get_nodes_in_group("boss")
	if not bosses.empty():
		assert(bosses.size() == 1)
		get_hud().get_node("HUD/BossHP/Progress").set_val(100.0 * bosses[0].HP / bosses[0].initial_HP)

func on_game_over():
	timer.stop()

# called by GameManager
func level_lost():
	return false

# called by GameManager
func level_won():
	if GameManager.debug and Input.is_key_pressed(KEY_TAB):
		return true
	var ship = GameManager.get_current_ship()
	if !ship or !ship.active():
		return false
	if type == LEVEL_TYPE.shooter:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.empty():
			return true
	elif type == LEVEL_TYPE.obstacles:
		var meteors = get_tree().get_nodes_in_group("meteors")
		for m in meteors:
			if m.get_global_pos().y < get_viewport_rect().size.y:
				return false
		return true
	return false

# called by GameManager
func get_hud():
	var hud = get_tree().get_nodes_in_group("hud")
	if hud.empty():
		return null
	return hud[0]
	
func time_bonus_cleared():
	if time_countdown <= 0:
		return true
	else:
		if  not add_time_bonus:
			time_bonus_label.set_text("TIME BONUS: " + str(time_countdown).pad_zeros(2))
			timer.stop()
			time_bonus_label.show()
			time_bonus_timer.start()
			add_time_bonus = true
	
func _on_LevelCountdown_timeout():
	if time_countdown > 0:
		time_countdown -= 1
		get_hud().set_time(time_countdown)


func _on_TimeBonusTimer_timeout():
	if time_countdown >= 0:
		time_bonus_label.set_text("TIME BONUS: " + str(time_countdown).pad_zeros(2))
		GameManager.add_score(10)
		time_countdown -= 1
	else:
		time_bonus_label.hide()
	
	
