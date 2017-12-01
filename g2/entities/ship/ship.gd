extends KinematicBody2D

const LASER_RECOVERY_MS = 200
const blinking_opacity_delta = 0.08

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
	on_hold = 5
}

var ship_state = SHIP_STATE.active
var dead_timestamp = -1
var last_laser_timestamp = -1.0
var ammo_type_ = AMMO_TYPE.regular
var warp_dest = Vector2(0.0,0.0)
var movement_offset = Vector2(0.0,0.0)
var velocity = Vector2()
var angular_velocity = float()

export(bool) var free_movement = true
export(bool) var can_shoot = true
export(float) var fake_speed = 0.0

onready var GameManager = get_node("/root/GameManager")
onready var bullet = preload("res://entities/bullet/bullet.tscn")
onready var death_particle_effect = get_node("ShipDeathParticles2D")
onready var flowing_particle_effect = get_node("ShipParticles2D")
onready var sprite = get_node("ShipSprite")
onready var col = get_node("ShipCollisionShape2D")
onready var ship_activation_timer = get_node("ShipActivationTimer")
onready var ship_blinking_timer = get_node("ShipBlinkingTimer")
onready var warp_animation = get_node("WarpAnimation")
onready var sfx = get_node("SamplePlayer")
onready var hitbox = get_node("HitBox")
onready var warp_sector = get_parent().get_node("WarpSector")
onready var fade_out = true



const SHIELD = preload("res://entities/ship/addons/addon_shield.tscn")
const COLLECTABLE_BASE = preload("res://entities/collectables/collectable_base.gd")
const BULLET_BASE = preload("res://entities/bullet/bullet_base.gd")
const ENEMY_BASE = preload("res://entities/enemy/enemy_base.gd")

func active():
	return ship_state in [SHIP_STATE.active, SHIP_STATE.on_hold]  and ship_activation_timer.get_time_left() <= 0.0

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
	
func on_hold():
	ship_state = SHIP_STATE.on_hold

func start_death():
	if ship_state == SHIP_STATE.death_start:
		return
	
	movement_offset = Vector2(0.0,0.0)
	ship_state = SHIP_STATE.death_start
	sfx.play("ship_explosion")
	dead_timestamp = OS.get_ticks_msec()
	death_particle_effect.set_emitting(true)
	flowing_particle_effect.set_emitting(false)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)
	hitbox.set_layer_mask(0)
	hitbox.set_collision_mask(0)
	ship_blinking_timer.stop()
	ship_activation_timer.stop()
	
func _fixed_process(delta):
	if ship_state == SHIP_STATE.death_start:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var death_anim_ended = secs_since_death > death_particle_effect.get_lifetime()
		var flowing_anim_ended = secs_since_death > flowing_particle_effect.get_lifetime()
		if death_anim_ended and flowing_anim_ended:
			GameManager.ship_destroyed(self)
			queue_free()
		return

	if ship_state != SHIP_STATE.active or get_tree().is_paused():
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
		var rand_x
		var rand_y
		var warp_cleared = false
		while not warp_cleared:
			rand_x = rand_range(ship_width, get_viewport_rect().size.x - ship_width)
			rand_y = rand_range(ship_height, get_viewport_rect().size.y - ship_height)
			warp_sector.set_pos(Vector2(rand_x, rand_y))
			var bodies = warp_sector.get_overlapping_bodies()
			if bodies.empty():
				warp_cleared = true;
			else:
				for body in bodies:
					var bad_warp = body.has_group("meteors") or body.has_group("enemies")
					if not bad_warp:
						warp_cleared = true;
						
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

	if GameManager.SHIP_ACCELERATION == 0.0:
		move_to(new_pos)
	else:
		velocity += movement_offset * GameManager.SHIP_ACCELERATION
		velocity *= GameManager.SHIP_DRAG
		velocity = velocity.clamped(GameManager.SHIP_MAX_SPEED)
		move(velocity * delta)
	if GameManager.SHIP_ANGULAR_ACCELERATION == 0.0:
		rotate(delta_rad)
	else:
		angular_velocity += delta_rad * GameManager.SHIP_ANGULAR_ACCELERATION
		angular_velocity *= GameManager.SHIP_ANGULAR_DRAG
		angular_velocity = clamp(angular_velocity, -GameManager.SHIP_MAX_ANGULAR_SPEED, GameManager.SHIP_MAX_ANGULAR_SPEED)
		rotate(angular_velocity * delta)

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
		sprite.hide()
		sfx.play("warp_drive_02")

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
	sprite.set_opacity(1.0)
	sprite.show()

func _on_WarpAnimation_finished():
	if (ship_state == SHIP_STATE.warp_start):
		set_pos(warp_dest) # actual warp
		ship_state = SHIP_STATE.warp_end
		sprite.show()
		warp_animation.set_frame(0)
		warp_animation.show()
		warp_animation.play()
	elif (ship_state == SHIP_STATE.warp_end):
		ship_state = SHIP_STATE.active
		warp_animation.stop()
		warp_animation.hide()
		ship_blinking_timer.start()
		ship_activation_timer.start()
		
func _on_ShipBlinkingTimer_timeout():
	var cur_ship_opacity = sprite.get_opacity()
	if fade_out:
		cur_ship_opacity -= blinking_opacity_delta
		if cur_ship_opacity <= 0.0:
			fade_out = false
	else:
		cur_ship_opacity += blinking_opacity_delta
		if cur_ship_opacity >= 1.0:
			fade_out = true
	sprite.set_opacity(cur_ship_opacity)

