extends Area2D

const LASER_RECOVERY_MS = 200
const BLINKING_SPEED = 8.0

enum AMMO_TYPE {
	regular = 0
	physical_pusher = 1
}

enum SHIP_STATE {
	active = 0
	warp_start = 1
	warp_end = 2
}

var ship_state = SHIP_STATE.active
var dead_timestamp = -1
var last_laser_timestamp = -1.0
var ammo_type_ = AMMO_TYPE.regular
var ammo_count_ = 99999
var warp_dest = Vector2(0.0,0.0)

export(bool) var free_movement = true
export(bool) var can_shoot = true
export(float) var fake_speed = 0.0 setget set_fake_speed

onready var GameManager = get_node("/root/GameManager")
onready var bullet = preload("res://Entities/Bullet/Bullet.tscn")
onready var death_particle_effect = get_node("ShipDeathParticles2D")
onready var flowing_particle_effect = get_node("ShipParticles2D")
onready var sprite = get_node("ShipSprite")
onready var col = get_node("ShipCollisionShape2D")
onready var ship_activation_timer = get_node("ShipActivationTimer")
onready var warp_transparency_timer = get_node("WarpTransparencyTimer")
onready var warp_animation = get_node("WarpAnimation")
onready var sfx = get_node("SamplePlayer")
onready var direction_camera = get_parent().get_node("DirectionCamera")

const SHIELD = preload("res://Entities/Ship/Addons/AddonShield.tscn")
const COLLECTABLE_BASE = preload("res://Entities/Collectables/CollectableBase.gd")

func active():
	return ship_state == SHIP_STATE.active and ship_activation_timer.get_time_left() <= 0.0

func bullet_instance():
	# TODO another type of bullet?
	if can_shoot and (ammo_count_ > 0):
		ammo_count_ -= 1
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
func clone(insatnce):
	insatnce.set_pos(get_pos())
	insatnce.set_rot(get_rot())
	insatnce.free_movement = free_movement
	insatnce.can_shoot = can_shoot
	insatnce.fake_speed = fake_speed
	return insatnce

func _ready():
	ship_state = SHIP_STATE.active
	if GameManager.warp_to_start_level:
		warp_ship(get_viewport_rect().size.x / 2.0, get_viewport_rect().size.y / 2.0)
		GameManager.warp_to_start_level = false
	sprite.get_material().set_shader_param("BLINKING_SPEED", BLINKING_SPEED)
	set_process(true)

func _process(delta):
	if dead_timestamp > 0:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var death_anim_ended = secs_since_death > death_particle_effect.get_lifetime()
		var flowing_anim_ended = secs_since_death > flowing_particle_effect.get_lifetime()
		if death_anim_ended and flowing_anim_ended:
			queue_free()
		return

	if GameManager.paused:
		return

	# if the ship is currently warping let _on_WarpTimer_timeout update ship position
	if ship_state in [SHIP_STATE.warp_start, SHIP_STATE.warp_end]:
		return

	var v = Vector2(0.0, -1.0).rotated(get_rot())
	var vn = Vector2(0.0, -1.0).rotated(get_rot() + PI/2.0)
	var new_pos = get_pos()
	var delta_rad = 0.0
	var f1 = 280.0
	var f2 = 4.0
	var movement_offset = Vector2(0,0)
	
	if Input.is_action_pressed("ui_warp") and self.active():
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
			movement_offset = vn * delta * f1
		else:
			delta_rad += delta * f2
	if Input.is_action_pressed("ui_right"):
		if not free_movement or Input.is_action_pressed("ui_starfe"):
			movement_offset = vn * delta * f1
		else:
			delta_rad -= delta * f2
	if Input.is_action_pressed("ui_select"):
		var now = OS.get_ticks_msec()
		if now - last_laser_timestamp > LASER_RECOVERY_MS:
			last_laser_timestamp = now
			var new_bullet = bullet_instance()
			if new_bullet:
				new_bullet.v_ = v * delta * f1 * 1.3
				new_bullet.set_pos(get_transform() * Vector2(0.0, -45.0))
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
		

	direction_camera.update(movement_offset)
	set_pos(new_pos)
	rotate(delta_rad)

func warp_ship(pos_x, pos_y):
	ship_state = SHIP_STATE.warp_start
	GameManager.dbg("warping to " + str(pos_x) + "," + str(pos_y))
	warp_dest = Vector2(pos_x, pos_y)
	warp_animation.set_frame(0)
	warp_animation.show()
	warp_animation.play()
	warp_transparency_timer.start()
	sfx.play("WarpDrive")

func start_death():
	dead_timestamp = OS.get_ticks_msec()
	death_particle_effect.set_emitting(true)
	flowing_particle_effect.set_emitting(false)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)
	GameManager.ship_destroyed(self)

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

func _on_ShipArea2D_area_enter( area ):
	if area extends COLLECTABLE_BASE: # FIXME not working!!!!
		return
	if not active():
		return
	GameManager.dbg(get_name() + " collision with " + area.get_name() + ". Starting death!")
	start_death()

func _on_ShipActivationTimer_timeout():
	sprite.get_material().set_shader_param("BLINKING_SPEED", 0.0)

func _on_WarpAnimation_finished():
	if (ship_state == SHIP_STATE.warp_start):
		set_pos(warp_dest)
		ship_state = SHIP_STATE.warp_end
		warp_animation.set_frame(0)
		warp_animation.show()
		warp_animation.play()
	elif (ship_state == SHIP_STATE.warp_end):
		ship_state = SHIP_STATE.active
		warp_animation.stop()
		warp_animation.hide()
		sprite.get_material().set_shader_param("BLINKING_SPEED", BLINKING_SPEED)
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
