extends RigidBody2D

onready var GameManager = get_node("/root/GameManager")
onready var anim = get_node("Anim")

export(int, 5) var HP = 5

func _ready():
	set_sleeping(false)

func _on_Hitbox_body_enter( body ):
	var dir = get_pos() - body.get_pos()
	body.start_death()
	anim.play("Hit")
	HP -= 1
	if HP == 0:
		queue_free()
