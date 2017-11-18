extends Node2D

onready var GameManager = get_node("/root/GameManager")

export(String, "shooter", "obstacles") var level_type = "shooter"
export(float, 0.0, 1000.0, 10.0) var level_speed = 90.0

enum LEVEL_TYPE {
	invalid = 0
	shooter = 1
	obstacles = 2
}
var type = LEVEL_TYPE.invalid

func init_type():
	if level_type == "shooter":
		type = LEVEL_TYPE.shooter
	elif level_type == "obstacles":
		type = LEVEL_TYPE.obstacles

func setup():
	if type == LEVEL_TYPE.obstacles:
		var ship = GameManager.get_current_ship()
		ship.fake_speed = level_speed
	elif type == LEVEL_TYPE.shooter:
		var ship = GameManager.get_current_ship()
		assert(ship)
		if GameManager.ship_pos_on_level_end != null:
			ship.set_pos(GameManager.ship_pos_on_level_end)
			ship.set_rot(GameManager.ship_rot_on_level_end)
	GameManager.level_ready(self)

func _ready():
	init_type()
	setup()
	set_process(true)

func _process(delta):
	if type == LEVEL_TYPE.shooter:
		pass
	elif type == LEVEL_TYPE.obstacles:
		var meteors = get_tree().get_nodes_in_group("meteors")
		for m in meteors:
			m.translate(Vector2(0.0, level_speed * delta))

# called by GameManager
func level_lost():
	return false

# called by GameManager
func level_won():
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