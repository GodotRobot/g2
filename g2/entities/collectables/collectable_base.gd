extends Node2D

enum TYPE {
	health = 0,
	warp = 1,
	shield = 2,
	boom = 3
}

export(int, 0, 100) var health = 0
export(int, 0, 100) var warp = 0
export(int, 0, 100) var shield = 0
export(int, 0, 100) var boom = 0

export(int, 0, 50) var score_bonus = 5

onready var GameManager = get_node("/root/GameManager")

var fake_speed = 0 setget set_fake_speed

func _ready():
	set_fixed_process(true)
	
func get_score():
	return score_bonus

func _fixed_process(delta):
	translate(Vector2(0, fake_speed * delta))

func set_fake_speed(speed):
	fake_speed = speed
	
func _on_Area2D_body_enter( body ):
	GameManager.collectable_collected(self, body)
	queue_free()

# ------------- factory --------------------
const SHIELD = preload("res://entities/collectables/collectable_shield.tscn")
const HEALTH = preload("res://entities/collectables/collectable_health.tscn")
const WARP = preload("res://entities/collectables/collectable_warp.tscn")
const BOOM = preload("res://entities/collectables/collectable_boom.tscn")
static func factory(collectable_type, collectable_value):
	if collectable_type == TYPE.shield:
		var s = SHIELD.instance()
		s.shield = collectable_value
		return s
	elif collectable_type == TYPE.health:
		var s = HEALTH.instance()
		s.health = collectable_value
		return s
	elif collectable_type == TYPE.warp:
		var s = WARP.instance()
		s.warp = collectable_value
		return s
	elif collectable_type == TYPE.boom:
		var s = BOOM.instance()
		s.boom = collectable_value
		return s
	# add more types here
	return null
# ------------------------------------------
