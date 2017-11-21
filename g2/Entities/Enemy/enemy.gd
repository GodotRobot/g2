extends Area2D

const course_added_noise = 0.0

const SHIP = preload("res://Entities/Ship/ship.gd")
const COLLECTABLE_BASE = preload("res://Entities/Collectables/CollectableBase.gd")

enum PERSONALITY_TYPE {
	random = 0,
	fall_from_sky = 1
}

const PERSONALITY_TO_TYPE = {
	"Random" : PERSONALITY_TYPE.random,
	"Fall from Sky" : PERSONALITY_TYPE.fall_from_sky
}

const DROP_TO_COLLECTABLE = {
	"Nothing" : null,
	"Warp" : COLLECTABLE_BASE.TYPE.warp,
	"Health" : COLLECTABLE_BASE.TYPE.health,
	"Shield" : COLLECTABLE_BASE.TYPE.shield
}

export(String, "Random", "Fall from Sky") var personality = "Random"
export(String, "Nothing", "Warp", "Health", "Shield") var drop = "Nothing"
export(int, 0, 100) var drop_value = 0
export(float, 0, 20, 0.5) var speed_min = 1.0
export(float, 0, 20, 0.5) var speed_max = 2.0
export(float, 0, 20, 0.5) var course_time_min = 5.0
export(float, 0, 20, 0.5) var course_time_max = 15.0

var time_to_course
var course
var dead_timestamp = -1
var personality_type
var drop_type # works with var drop_value
var wake_up = -1

onready var GameManager = get_node("/root/GameManager")
onready var death_particle_effect = get_node("EnemyDeathParticles2D")
onready var flowing_particle_effect = get_node("EnemyParticles2D")
onready var sprite = get_node("EnemySprite")
onready var sfx = get_node("SamplePlayer")

func is_dead():
	return dead_timestamp > 0

func init_course():
	if personality_type == PERSONALITY_TYPE.random:
		time_to_course = rand_range(course_time_min, course_time_max)
		course = Vector2(rand_range(-1, 1), rand_range(-1, 1))
		course *= 2.0 * rand_range(speed_min, speed_max)
	elif personality_type == PERSONALITY_TYPE.fall_from_sky:
		set_pos(Vector2(randf() * 1024, 0)) # override position TODO viewport width
		time_to_course = 99999.9
		var sec_to_wait = (randf() * 10.0)
		wake_up = OS.get_ticks_msec() + 1000.0 * sec_to_wait
		course = Vector2(0.0, 1.0)

func init_from_exports():
	personality_type = PERSONALITY_TO_TYPE[personality]
	drop_type = DROP_TO_COLLECTABLE[drop]

func _ready():
	init_from_exports()
	init_course()
	set_process(true)

func _process(delta):
	if OS.get_ticks_msec() < wake_up:
		return
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
		if personality_type == PERSONALITY_TYPE.random:
			new_pos.y = get_viewport_rect().size.y
			course.y = -course.y
		elif personality_type == PERSONALITY_TYPE.fall_from_sky:
			new_pos.y = 0
	var dir = new_pos - get_pos()
	flowing_particle_effect.set_param(Particles2D.PARAM_DIRECTION, rad2deg(dir.angle()))
	sprite.set_global_rot(dir.angle())
	set_pos(new_pos)

func _exit_tree():
	if dead_timestamp == -1:
		start_death()

func start_death():
	dead_timestamp = OS.get_ticks_msec()
	death_particle_effect.set_emitting(true)
	flowing_particle_effect.set_emitting(false)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)
	sfx.play("explosion1")
	remove_from_group("enemies")
	GameManager.enemy_destroyed(self)

func _on_EnemyArea2D_area_enter( area ):
	GameManager.dbg(get_name() + " collision with " + area.get_name())
	if area extends SHIP:
		if not area.active():
			return
	start_death()