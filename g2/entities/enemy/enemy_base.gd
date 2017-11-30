extends KinematicBody2D

const SHIP_BASE = preload("res://entities/ship/ship.gd")
const BULLET_BASE = preload("res://entities/bullet/bullet_base.gd")
const COLLECTABLE_BASE = preload("res://entities/collectables/collectable_base.gd")
const BULLET = preload("res://entities/bullet/enemy_bullet.tscn")
const DRONE = preload("res://entities/enemy/enemy_drone.tscn")

enum PERSONALITY_TYPE {
	random = 0,
	shooter = 1,
	drone = 2,
	boss = 3
}

const PERSONALITY_TO_TYPE = {
	"Random" : PERSONALITY_TYPE.random,
	"Shooter" : PERSONALITY_TYPE.shooter,
	"Drone" : PERSONALITY_TYPE.drone,
	"Boss" : PERSONALITY_TYPE.boss
}

const DROP_TO_COLLECTABLE = {
	"Nothing" : null,
	"Warp" : COLLECTABLE_BASE.TYPE.warp,
	"Health" : COLLECTABLE_BASE.TYPE.health,
	"Shield" : COLLECTABLE_BASE.TYPE.shield
}

export(String, "Random", "Shooter", "Drone", "Boss") var personality = "Random"
export(String, "Nothing", "Warp", "Health", "Shield") var drop = "Nothing"
export(int, 0, 100) var drop_value = 10
export(float, 0, 20, 0.5) var speed_min = 1.0
export(float, 0, 20, 0.5) var speed_max = 2.0
export(float, 0, 20, 0.5) var course_time_min = 5.0
export(float, 0, 20, 0.5) var course_time_max = 15.0
export(float, 0.0, 3.0, 0.1) var acceleration = 0.6
export(int, 1, 100) var HP = 1
export(int, 1, 100) var kill_score = 5
export(float, 0.0, 30.0, 0.1) var fire_rate_min = 0.5
export(float, 0.0, 30.0, 0.1) var fire_rate_max = 1.5
export(int, -1, 100) var bullets_left = -1 # -1 is infinite

var velocity = Vector2()
var dead_timestamp = -1
var personality_type
var drop_type # works with var drop_value
var shoot_timer = Timer.new()
var shots_fired = 0

onready var GameManager = get_node("/root/GameManager")
onready var death_effect = get_node("DeathEffect")
onready var flow_effect = get_node("Sprite/FlowEffect")
onready var sprite = get_node("Sprite")
onready var sfx = get_node("SamplePlayer")
onready var course_timer = get_node("CourseTimer")
onready var hitbox = get_node("HitBox")
onready var initial_HP = HP
onready var engine_anim = get_node("Sprite/Engine/AnimationPlayer")

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

func get_dir_to_ship():
	var ship = GameManager.get_current_ship()
	if not ship:
		return (get_viewport().get_rect().size / 2 - get_pos()).normalized()
	return (ship.get_pos() - get_pos()).normalized()

func get_bullet_spawn_point():
	var spawn_points = get_tree().get_nodes_in_group("spawn")
	return spawn_points[shots_fired % spawn_points.size()]

func shoot():
	if not ready_to_shoot():
		return
	if personality_type == PERSONALITY_TYPE.shooter:
		var new_bullet = BULLET.instance()
		if new_bullet:
			var bullet_spawn_point = get_bullet_spawn_point()
			var xform = bullet_spawn_point.get_global_transform()
			new_bullet.set_global_transform(xform)
			new_bullet.velocity = Vector2(0.0, 1.0).rotated(xform.get_rotation())
			get_parent().add_child(new_bullet)
			sfx.play("sfx_laser1")
	elif personality_type == PERSONALITY_TYPE.boss:
		var cur_ship = GameManager.get_current_ship()
		if cur_ship and cur_ship.active():
			var new_drone = DRONE.instance()
			if new_drone:
				var bullet_spawn_point = get_bullet_spawn_point()
				var xform = bullet_spawn_point.get_global_transform()
				new_drone.set_global_transform(xform)
				get_parent().add_child(new_drone)
	shots_fired += 1

func init_shoot_timer():
	# shoot timer - TODO make it a proper node via the scene
	shoot_timer.set_wait_time(0.5)
	shoot_timer.set_timer_process_mode(Timer.TIMER_PROCESS_IDLE)
	shoot_timer.set_one_shot(true)
	add_child(shoot_timer)
	shoot_timer.start()

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
	elif personality_type == PERSONALITY_TYPE.drone:
		velocity = get_dir_to_ship()
		velocity *= 200.0
	elif personality_type == PERSONALITY_TYPE.boss:
		velocity = get_dir_to_ship()
		velocity *= 10.0

func init_from_exports():
	personality_type = PERSONALITY_TO_TYPE[personality]
	drop_type = DROP_TO_COLLECTABLE[drop]

func _ready():
	init_from_exports()
	init_velocity()
	init_shoot_timer()
	if engine_anim != null:
		engine_anim.play("EngineBurn")
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

func ready_to_shoot():
	if bullets_left != -1 and shots_fired >= bullets_left:
		return false
	var time_left = shoot_timer.get_time_left()
	if time_left > 0.0:
		return false
	var next_wait_sec = rand_range(fire_rate_min, fire_rate_max)
	shoot_timer.set_wait_time(next_wait_sec)
	shoot_timer.start()
	return true

func _fixed_process(delta):
	if dead_timestamp > 0:
		var secs_since_death = float(OS.get_ticks_msec() - dead_timestamp) / 1000.0
		update_death(secs_since_death)
		var death_anim_ended = secs_since_death > death_effect.get_lifetime()
		var flowing_anim_ended = secs_since_death > flow_effect.get_lifetime()
		if death_anim_ended and flowing_anim_ended:
			queue_free()
		if secs_since_death > GameManager.LEVEL_POST_MORTEM_DELAY_SEC:
			if get_groups().find("enemies") != -1:
				remove_from_group("enemies")
		return

	shoot()

	if personality_type == PERSONALITY_TYPE.drone and acceleration != -1.0:
		velocity *= delta * (60.0 + acceleration)
	var motion = velocity * delta
	var angle = motion.angle()
	# special check to support static enemies in predefined positions
	if velocity.length_squared() == 0:
		var v = Vector2(0.0, 1.0).rotated(get_rot())
		motion = 0.001 * v
		angle = motion.angle()
		flow_effect.set_param(Particles2D.PARAM_DIRECTION, rad2deg(angle))
		set_global_rot(angle)
		return
	motion = move(motion)
	var impulse = is_outside()
	if (is_colliding() or impulse != null):
		move(motion)
		angle = motion.angle()
		init_velocity(impulse)

	#flow_effect.set_param(Particles2D.PARAM_DIRECTION, rad2deg(angle))
	set_global_rot(angle)

var dead_sprite_parts = Array()
func update_death(secs_since_death):
	for part in dead_sprite_parts:
		var max_time = 1.5
		var w = clamp(secs_since_death / max_time, 0.0, 1.0)
		part.set_pos(part.get_pos() + 3.0 * w * part.get_pos().normalized())
		part.rotate(sign(part.get_pos().angle() + 0.001) * 0.07)
		part.scale(Vector2(0.99,0.99))
		part.set_opacity(1.0 - w)
	
func start_death():
	if dead_timestamp != -1:
		return
	dead_timestamp = OS.get_ticks_msec()
	death_effect.set_emitting(true)
	# go over all children of sprite, which are the visible parts of this enemy
	var multipart = false
	if sprite.get_child_count() > 0:
		for part in sprite.get_children():
			if part extends Sprite:
				multipart = true
				dead_sprite_parts.push_back(part)
				sprite.remove_child(part) # break hierarchy so that parts will flow independently
				add_child(part)
				part.set_owner(self)
			if part extends Particles2D:
				part.set_emitting(false)
	if multipart:		
		dead_sprite_parts.push_back(sprite)
	else:
		sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)
	hitbox.set_layer_mask(0)
	hitbox.set_collision_mask(0)
	sfx.play("enemy_explosion1")
	GameManager.enemy_destroyed(self)

func _on_CourseTimer_timeout():
	init_velocity(null)
	
func hit():
	HP -= 1
	if HP <= 0:
		start_death()
		return
	if has_node("Anim"):
		get_node("Anim").play("Hit")

func _on_Area2D_body_enter( body ):
	GameManager.dbg("enemy: " + get_name() + " collision with " + body.get_name())
	if body extends BULLET_BASE or (body extends SHIP_BASE and body.active()):
		body.start_death() # we take the bullet / active ship with us
		hit()