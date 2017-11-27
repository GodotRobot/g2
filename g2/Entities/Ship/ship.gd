extends KinematicBody2D

const LASER_RECOVERY_MS = 200

enum AMMO_TYPE {
	regular = 0
	physical_pusher = 1
}

enum SHIP_STATE {
	active = 0
	warp_start = 1
	warp_end = 2
	death_start = 3
	death_end = 4
}

var ship_state = SHIP_STATE.active
var dead_timestamp = -1
var last_laser_timestamp = -1.0
var ammo_type_ = AMMO_TYPE.regular
var warp_dest = Vector2(0.0,0.0)
var movement_offset = Vector2(0.0,0.0)

export(bool) var free_movement = true
export(bool) var can_shoot = true
export(float) var fake_speed = 0.0

onready var GameManager = get_node("/root/GameManager")
onready var bullet = preload("res://Entities/Bullet/Bullet.tscn")
onready var death_particle_effect = get_node("ShipDeathParticles2D")
onready var flowing_particle_effect = get_node("ShipParticles2D")
onready var sprite = get_node("ShipSprite")
onready var col = get_node("ShipCollisionShape2D")
onready var ship_activation_timer = get_node("ShipActivationTimer")
onready var ship_blinking_timer = get_node("ShipBlinkingTimer")
onready var warp_transparency_timer = get_node("WarpTransparencyTimer")
onready var warp_animation = get_node("WarpAnimation")
onready var sfx = get_node("SamplePlayer")
onready var hitbox = get_node("HitBox")



const SHIELD = preload("res://Entities/Ship/Addons/AddonShield.tscn")
const COLLECTABLE_BASE = preload("res://Entities/Collectables/CollectableBase.gd")
const BULLET_BASE = preload("res://Entities/Bullet/BulletBase.gd")
const ENEMY_BASE = preload("res://Entities/Enemy/EnemyBase.gd")

func active():
	return ship_state == SHIP_STATE.active and ship_activation_timer.get_time_left() <= 0.0

func bullet_instance():
	# TODO another type of bullet?
	if can_shoot:
		return bullet.instance()
	else:
		return null

func set_fake_speed(new_speed):
	if flowing_particle_effect and new_speed != 0.0:
		flowing_particle_effect.set_param(Particles2D.PARAM_SPREAD, 0.0)
		flowing_particle_effect.set_param(Particles2D.PARAM_LINEAR_VELOCITY, new_speed)
		flowing_particle_effect.set_randomness(Particles2D.PARAM_LINEAR_VELOCITY, 0.0)
	fake_speed = new_speed

# copy important stuff into instance, and return it
func clone(instance):
	instance.set_pos(get_pos())
	instance.set_rot(get_rot())
	instance.free_movement = free_movement
	instance.can_shoot = can_shoot
	instance.set_fake_speed(fake_speed)
	return instance

func _ready():
	ship_state = SHIP_STATE.active
	if GameManager.warp_to_start_level:
		warp_ship(GameManager.current_scene.initial_pos.x,GameManager.current_scene.initial_pos.y)
		GameManager.warp_to_start_level = false
	ship_blinking_timer.start()
	ship_activation_timer.start()
	set_fixed_process(true)
	

func start_death():
	if ship_state == SHIP_STATE.death_start:
		return
	
	movement_offset = Vector2(0.0,0.0)
	ship_state = SHIP_STATE.death_start
	sfx.play("Ship_Explosion")
	dead_timestamp = OS.get_ticks_msec()
	death_particle_effect.set_emitting(true)
	flowing_particle_effect.set_emitting(false)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)
	hitbox.set_layer_mask(0)
	hitbox.set_collision_mask(0)
	
func _fixed_process(delta):
	if ship_state == SHIP_STATE.death_start:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var death_anim_ended = secs_since_death > death_particle_effect.get_lifetime()
		var flowing_anim_ended = secs_since_death > flowing_particle_effect.get_lifetime()
		if death_anim_ended and flowing_anim_ended:
			GameManager.ship_destroyed(self)
			queue_free()
		return

	if ship_state != SHIP_STATE.active or GameManager.paused:
		return

	var v = Vector2(0.0, -1.0).rotated(get_rot())
	var vn = Vector2(0.0, -1.0).rotated(get_rot() + PI/2.0)
	var new_pos = get_pos()
	var delta_rad = 0.0
	var f1 = 280.0
	var f2 = 4.0
	movement_offset = Vector2(0,0)

	if Input.is_action_pressed("ui_warp") and ship_state == SHIP_STATE.active:
		var ship_width = sprite.get_texture().get_width()
		var ship_height = sprite.get_texture().get_height()
		var rand_x = rand_range(ship_width, get_viewport_rect().size.x - ship_width)
		var rand_y = rand_range(ship_height, get_viewport_rect().size.y - ship_height)
		warp_ship(rand_x, rand_y)
		return

	if Input.is_action_pressed("ui_up"):
		movement_offset = v * delta * f1
	if Input.is_action_pressed("ui_down"):
		movement_offset = -(v * delta * f1)
	if Input.is_action_pressed("ui_left"):
		if not free_movement or Input.is_action_pressed("ui_starfe"):
			movement_offset += vn * delta * f1
		else:
			delta_rad += delta * f2
	if Input.is_action_pressed("ui_right"):
		if not free_movement or Input.is_action_pressed("ui_starfe"):
			movement_offset += -(vn * delta * f1)
		else:
			delta_rad -= delta * f2
	if Input.is_action_pressed("ui_select"):
		var now = OS.get_ticks_msec()
		if now - last_laser_timestamp > LASER_RECOVERY_MS:
			last_laser_timestamp = now
			var new_bullet = bullet_instance()
			if new_bullet:
				new_bullet.velocity = v
				new_bullet.set_global_transform(get_global_transform())
				new_bullet.translate(v * GameManager.BULLET_AHEAD)
				get_parent().add_child(new_bullet)
				sfx.play("sfx_laser1")

	new_pos += movement_offset

	# if the ship flies out of the viewport, activate warp to the other direction
	if new_pos.x > get_viewport_rect().size.x:
		var pos_x = 1
		var pos_y = get_pos().y
		warp_ship(pos_x,pos_y)

	elif new_pos.x < 0:
		var pos_x = get_viewport_rect().size.x - 1
		var pos_y = get_pos().y
		warp_ship(pos_x,pos_y)

	elif new_pos.y < 0:
		var pos_x = get_pos().x
		var pos_y = get_viewport_rect().size.y - 1
		warp_ship(pos_x,pos_y)

	elif new_pos.y > get_viewport_rect().size.y:
		var pos_x = get_pos().x
		var pos_y = 1
		warp_ship(pos_x,pos_y)

	move_to(new_pos)
	rotate(delta_rad)

func warp_ship(pos_x, pos_y):
	if GameManager.cur_warp == 0:
		# trying to warp with no charges left
		start_death()
	else:
		ship_state = SHIP_STATE.warp_start
		if not GameManager.warp_to_start_level:
			# tell GameManager the ship warped only after the initial level warp
			GameManager.ship_warped()
		GameManager.dbg("warping to " + str(pos_x) + "," + str(pos_y))
		warp_dest = Vector2(pos_x, pos_y)
		warp_animation.set_frame(0)
		warp_animation.show()
		warp_animation.play()
		warp_transparency_timer.start()
		sfx.play("WarpDrive")

func add_shield(shield):
	GameManager.dbg(get_name() + " adding " + String(shield) + " shield")
	var shield = null
	if not has_node("shield"):
		shield = SHIELD.instance()
		add_child(shield)
	else:
		shield = get_node("shield")
		assert shield
	GameManager.dbg(get_name() + " now has shield at " + String(shield.power))
	

func _on_HitBoxArea_body_enter( body ):
	if not active():
		return
	GameManager.dbg("ship: " + get_name() + " collision with " + body.get_name() + ". Starting death!")
	if body extends BULLET_BASE or body extends ENEMY_BASE:
		body.start_death()
	start_death()

func _on_ShipActivationTimer_timeout():
	ship_blinking_timer.stop()
	sprite.show()

func _on_WarpAnimation_finished():
	if (ship_state == SHIP_STATE.warp_start):
		set_pos(warp_dest) # actual warp
		ship_state = SHIP_STATE.warp_end
		warp_animation.set_frame(0)
		warp_animation.show()
		warp_animation.play()
	elif (ship_state == SHIP_STATE.warp_end):
		ship_state = SHIP_STATE.active
		warp_animation.stop()
		warp_animation.hide()
		ship_blinking_timer.start()
		ship_activation_timer.start()

func _on_WarpTransparencyTimer_timeout():
	var ship_opacity = sprite.get_opacity()
	if (ship_state == SHIP_STATE.warp_start):
			if (ship_opacity > 0):
				ship_opacity -= 0.1
	if (ship_state == SHIP_STATE.warp_end):
		if (ship_opacity < 1.0):
				ship_opacity += 0.1
	sprite.set_opacity(ship_opacity)


func _on_ShipBlinkingTimer_timeout():
	if sprite.is_visible():
		sprite.hide()
	else:
		sprite.show()
