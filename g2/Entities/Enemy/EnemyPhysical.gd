extends RigidBody2D

const max_time_to_course = 35.0
const max_course_speed = 1.0
const course_added_noise = 0.0
const MAX_LIVES = 3

var time_to_course
var course
var dead_timestamp = -1
var lives = 3

onready var GameManager = get_node("/root/GameManager")
onready var death_particle_effect = get_node("EnemyDeathParticles2D")
onready var flowing_particle_effect = get_node("EnemyParticles2D")
onready var sprite = get_node("EnemySprite")
onready var sfx = get_node("SamplePlayer")

func set_behavior(behavior):
	pass

func is_dead():
	return dead_timestamp > 0

func init_course():
	time_to_course = randf() * max_time_to_course # 0..10 secs
	var v = Vector2(rand_range(-1, 1), rand_range(-1, 1))
	v *= 200.0 * rand_range(1.0, max_course_speed)
	set_linear_velocity(v)

func _ready():
	GameManager.dbg("enemy " + get_name() + " ready")
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
	var p = get_pos()
	var v = get_linear_velocity()
	if p.x < 0 and v.x < 0:
		v.x = -v.x
	if p.y < 0 and v.y < 0:
		v.y = -v.y
	if p.x > get_viewport_rect().size.x and v.x > 0:
		v.x = -v.x
	if p.y > get_viewport_rect().size.y and v.y > 0:
		v.y = -v.y
	if v != get_linear_velocity():
		set_linear_velocity(v)

func start_death_sequence():
	dead_timestamp = OS.get_ticks_msec()
	death_particle_effect.set_emitting(true)
	flowing_particle_effect.set_emitting(false)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)

func _on_EnemyArea2D_area_enter( area ):
	if area.has_method("active") and not area.active():
		return
	start_death_sequence()

func reduce_life():
	lives -= 1
	var m = float(lives) / MAX_LIVES
	sprite.set_modulate(Color(m, m, m))
	if lives == 0:
		start_death_sequence()

func _on_EnemyArea2D_body_enter( body ):
	body.start_death_sequence(get_pos())
	reduce_life()
	GameManager.dbg("enemy " + get_name() + " got hit by " + body.get_name())
