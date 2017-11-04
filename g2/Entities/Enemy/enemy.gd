extends Area2D

const max_time_to_course = 35.0
const max_course_speed = 1.0
const course_added_noise = 0.0

var time_to_course
var course
var dead_timestamp = -1

onready var death_particle_effect = get_node("EnemyDeathParticles2D")
onready var flowing_particle_effect = get_node("EnemyParticles2D")
onready var sprite = get_node("EnemySprite")
onready var col = get_node("EnemyCollisionShape2D")

func init_course():
	time_to_course = randf() * max_time_to_course # 0..10 secs
	course = Vector2(rand_range(-1, 1), rand_range(-1, 1))
	course *= 2.0 * rand_range(1.0, max_course_speed)

func _ready():
	print("enemy ready")
	init_course()
	rotate(PI)
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)

func _process(delta):
	if dead_timestamp > 0:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var death_anim_ended = secs_since_death > death_particle_effect.get_lifetime()
		var flowing_anim_ended = secs_since_death > flowing_particle_effect.get_lifetime()
		if death_anim_ended and flowing_anim_ended:
			queue_free()
		return
	time_to_course -= delta
	if time_to_course < 0.0:
		init_course()
	var local_change = delta * course_added_noise * Vector2(rand_range(-1, 1), rand_range(-1, 1))
	var new_pos = get_pos() + course + local_change
	if new_pos.x < 0:
		new_pos.x = 0
		course.x = -course.x
	if new_pos.y < 0:
		new_pos.y = 0
		course.y = -course.y
	if new_pos.x > get_viewport_rect().size.x:
		new_pos.x = get_viewport_rect().size.x
		course.x = -course.x
	if new_pos.y > get_viewport_rect().size.y:
		new_pos.y = get_viewport_rect().size.y
		course.y = -course.y
	var dir = new_pos - get_pos()
	flowing_particle_effect.set_param(Particles2D.PARAM_DIRECTION, rad2deg(dir.angle()))
	set_pos(new_pos)

func _on_EnemyArea2D_area_enter( area ):
	dead_timestamp = OS.get_ticks_msec()
	death_particle_effect.set_emitting(true)
	flowing_particle_effect.set_emitting(false)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)