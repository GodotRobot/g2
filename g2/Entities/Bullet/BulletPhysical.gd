extends RigidBody2D

onready var impact = get_node("Impact")
onready var sprite = get_node("BulletSprite")

var v_
var dead_timestamp = -1

func _ready():
	set_linear_velocity(v_ * 80.0)
	impact.set_emitting(false)
	set_process(true)

func _process(delta):
	if dead_timestamp > 0:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var death_anim_ended = secs_since_death > impact.get_lifetime()
		if death_anim_ended:
			queue_free()
		return
	var v = get_pos()
	if v.y < 0 or v.y > get_viewport_rect().size.y or v.x < 0 or v.x > get_viewport_rect().size.x:
		queue_free()

func start_death_sequence(src):
	dead_timestamp = OS.get_ticks_msec()
	set_linear_velocity(Vector2(0,0))
	impact.set_rot(get_angle_to(src))
	impact.set_emitting(true)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)