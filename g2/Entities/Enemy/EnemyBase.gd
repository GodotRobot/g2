extends KinematicBody2D

const SHIP_BASE = preload("res://Entities/Ship/ship.gd")
const BULLET_BASE = preload("res://Entities/Bullet/BulletBase.gd")
const COLLECTABLE_BASE = preload("res://Entities/Collectables/CollectableBase.gd")
const BULLET = preload("res://Entities/Bullet/Bullet.tscn")

enum PERSONALITY_TYPE {
	random = 0,
	shooter = 1
}

const PERSONALITY_TO_TYPE = {
	"Random" : PERSONALITY_TYPE.random,
	"Shooter" : PERSONALITY_TYPE.shooter
}

const DROP_TO_COLLECTABLE = {
	"Nothing" : null,
	"Warp" : COLLECTABLE_BASE.TYPE.warp,
	"Health" : COLLECTABLE_BASE.TYPE.health,
	"Shield" : COLLECTABLE_BASE.TYPE.shield
}

export(String, "Random", "Shooter") var personality = "Random"
export(String, "Nothing", "Warp", "Health", "Shield") var drop = "Nothing"
export(int, 0, 100) var drop_value = 10
export(float, 0, 20, 0.5) var speed_min = 1.0
export(float, 0, 20, 0.5) var speed_max = 2.0
export(float, 0, 20, 0.5) var course_time_min = 5.0
export(float, 0, 20, 0.5) var course_time_max = 15.0

var velocity = Vector2()
var dead_timestamp = -1
var personality_type
var drop_type # works with var drop_value

onready var GameManager = get_node("/root/GameManager")
onready var death_effect = get_node("DeathEffect")
onready var flow_effect = get_node("FlowEffect")
onready var sprite = get_node("Sprite")
onready var sfx = get_node("SamplePlayer")
onready var course_timer = get_node("CourseTimer")
onready var hitbox = get_node("HitBox")

func is_dead():
	return dead_timestamp > 0

func calc_random_velocity(impulse):
	var v = Vector2(rand_range(-1, 1), rand_range(-1, 1))
	if impulse != null:
		if impulse.x != 0.0:
			v.x = impulse.x * rand_range(0.0, 1.0)
		elif impulse.y != 0.0:
			v.y = impulse.y * rand_range(0.0, 1.0)
	v *= 200.0 * rand_range(speed_min, speed_max)
	return v

func shoot():	
	if personality_type != PERSONALITY_TYPE.shooter or !is_ship_in_funnel():
		return

	var new_bullet = BULLET.instance()
	if new_bullet:
		new_bullet.velocity = velocity
		if velocity.length_squared() == 0:
			new_bullet.velocity = Vector2(0.0, 1.0).rotated(get_rot())
		# IDFK why sprite is needed, but calling the root's get_global_transform gives Identity for rotation :|
		new_bullet.set_global_transform(sprite.get_global_transform())
		new_bullet.set_layer_mask(16)
		new_bullet.set_collision_mask(0)
		get_parent().add_child(new_bullet)
		sfx.play("sfx_laser1")

func init_velocity(impulse = null):
	if personality_type == PERSONALITY_TYPE.random:
		var time_to_course = rand_range(course_time_min, course_time_max)
		velocity = calc_random_velocity(impulse)
		course_timer.set_wait_time(time_to_course)
		course_timer.start()
	elif personality_type == PERSONALITY_TYPE.shooter:
		var time_to_course = rand_range(course_time_min, course_time_max)
		velocity = calc_random_velocity(impulse)
		course_timer.set_wait_time(time_to_course)
		course_timer.start()

func init_from_exports():
	personality_type = PERSONALITY_TO_TYPE[personality]
	drop_type = DROP_TO_COLLECTABLE[drop]

func _ready():
	init_from_exports()
	init_velocity()
	set_fixed_process(true)

func is_outside():
	var pos = get_pos()
	var impulse = null
	if pos.x < 0:
		impulse = Vector2(1.0, 0.0)
	elif pos.x > get_viewport_rect().size.x:
		impulse = Vector2(-1.0, 0.0)
	elif pos.y < 0:
		impulse = Vector2(0.0, 1.0)
	elif pos.y > get_viewport_rect().size.y:
		impulse = Vector2(0.0, -1.0)
	return impulse

func is_ship_in_funnel():
	return randf() < 0.01

func _fixed_process(delta):
	if dead_timestamp > 0:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var death_anim_ended = secs_since_death > death_effect.get_lifetime()
		var flowing_anim_ended = secs_since_death > flow_effect.get_lifetime()
		if death_anim_ended and flowing_anim_ended:
			queue_free()
		if secs_since_death > GameManager.LEVEL_POST_MORTEM_DELAY_SEC:
			if get_groups().find("enemies") != -1:
				remove_from_group("enemies")
		return

	shoot()
	
	var motion = velocity * delta
	var angle = motion.angle()
	
	# special check to support static enemies in predefined positions
	if velocity.length_squared() == 0:
		var v = Vector2(0.0, 1.0).rotated(get_rot())
		motion = 0.001 * v
		angle = motion.angle()
		flow_effect.set_param(Particles2D.PARAM_DIRECTION, rad2deg(angle))
		sprite.set_global_rot(angle)
		return
	
	motion = move(motion)

	var impulse = is_outside()
	if (is_colliding() or impulse != null):
		move(motion)
		angle = motion.angle()
		init_velocity(impulse)

	flow_effect.set_param(Particles2D.PARAM_DIRECTION, rad2deg(angle))
	sprite.set_global_rot(angle)

func start_death():
	dead_timestamp = OS.get_ticks_msec()
	death_effect.set_emitting(true)
	flow_effect.set_emitting(false)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)
	hitbox.set_layer_mask(0)
	hitbox.set_collision_mask(0)
	sfx.play("Enemy_Explosion1")
	GameManager.enemy_destroyed(self)

func _on_CourseTimer_timeout():
	init_velocity(null)

func _on_Area2D_body_enter( body ):
	GameManager.dbg(get_name() + " collision with " + body.get_name())
	if body extends SHIP_BASE:
		if not body.active():
			return # inactive ship can't harm us
	if body extends BULLET_BASE:
		body.start_death() # we take the bullet with us
	start_death()
