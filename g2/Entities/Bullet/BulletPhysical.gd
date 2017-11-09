extends RigidBody2D

var v_

func _ready():
	set_linear_velocity(v_ * 120.0)
	set_process(true)

func _process(delta):
	var v = get_linear_velocity()
	if v.y < 0 or v.y > get_viewport_rect().size.y or v.x < 0 or v.x > get_viewport_rect().size.x:
		queue_free()
