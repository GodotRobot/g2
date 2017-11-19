extends Node2D

onready var GameManager = get_node("/root/GameManager")

func _ready():
	pass

func _on_Area2D_area_enter( area ):
	GameManager.collectable_collected(self, area)
	queue_free()
