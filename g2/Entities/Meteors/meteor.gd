extends RigidBody2D

onready var GameManager = get_node("/root/GameManager")

func _ready():
	set_fixed_process(true)
	set_sleeping(false)

func _fixed_process(delta):
	pass
