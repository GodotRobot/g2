extends Node2D

enum TYPE {
	health = 0,
	warp = 1,
	shield = 2
}

export(int, 0, 100) var health = 0
export(int, 0, 100) var warp = 0
export(int, 0, 100) var shield = 0

onready var GameManager = get_node("/root/GameManager")

func _ready():
	pass

func _on_Area2D_body_enter( body ):
	GameManager.collectable_collected(self, body)
	queue_free()
	
# ------------- factory --------------------
const SHIELD = preload("res://Entities/Collectables/CollectableShield.tscn")
static func factory(collectable_type, collectable_value):
	if collectable_type == TYPE.shield:
		var s = SHIELD.instance()
		s.shield = collectable_value
		return s
	# add more types here
	return null
# ------------------------------------------
