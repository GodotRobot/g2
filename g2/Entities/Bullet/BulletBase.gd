extends KinematicBody2D

var velocity
var dead_timestamp = -1

onready var GameManager = get_node("/root/GameManager")
onready var effect = get_node("EngineEffect")
onready var sprite = get_node("Sprite")
onready var light = get_node("Glow")

func _ready():
	set_z(-999)
	set_fixed_process(true)

func is_outside():
	var pos = get_pos()
	if pos.x < 0 or pos.x > get_viewport_rect().size.x or pos.y < 0 or pos.y > get_viewport_rect().size.y:
		return true
	return false

func _fixed_process(delta):
	if dead_timestamp > 0:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var effect_anim_ended = secs_since_death > effect.get_lifetime()
		if effect_anim_ended:
			queue_free() # final death, all traces (particles) are also dead by now
		return
	var motion = velocity.normalized() * GameManager.BULLET_SPEED * delta
	move(motion)
	if is_outside():
		start_death()

func start_death():
	velocity = Vector2(0.0, 0.0)
	dead_timestamp = OS.get_ticks_msec()
	effect.set_emitting(false)
	light.set_enabled(false)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)

func _exit_tree():
	if dead_timestamp == -1:
		start_death()

