extends Node2D

export(int, 0, 100) var health = 0
export(int, 0, 100) var warp = 0
export(int, 0, 100) var shield = 0

onready var GameManager = get_node("/root/GameManager")

func _ready():
	pass

func _on_Area2D_area_enter( area ):
	GameManager.collectable_collected(self, area)
	queue_free()
