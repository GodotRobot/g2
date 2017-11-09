extends Area2D

const LASER_RECOVERY_MS = 200

enum AMMO_TYPE {
	regular = 0
	physical_pusher = 1
}

var dead_timestamp = -1
var last_laser_timestamp = -1.0
var ammo_type_ = AMMO_TYPE.regular
var ammo_count_ = 99999

onready var game = get_tree().get_root().get_node("game")
onready var bullet = preload("res://Entities/Bullet/Bullet.tscn")
onready var bullet_physical = preload("res://Entities/Bullet/BulletPhysical.tscn")
onready var death_particle_effect = get_node("ShipDeathParticles2D")
onready var flowing_particle_effect = get_node("ShipParticles2D")
onready var sprite = get_node("ShipSprite")
onready var col = get_node("ShipCollisionShape2D")
onready var timer = get_node("ShipActivationTimer")
onready var blink_timer = get_node("ActivationBlinkTimer")
onready var sfx = get_node("SamplePlayer")

func active():
	return timer.get_time_left() <= 0.0

func ship_destroyed(area):
	game.ship_destroyed()
	#print(get_name(), " <-> ", area.get_name())
	#trigger kill effect TODO

func bullet_instance():
	if ammo_type_ == AMMO_TYPE.regular:
		return bullet.instance()
	elif ammo_type_ == AMMO_TYPE.physical_pusher:
		return bullet_physical.instance()
	return null

func _ready():
	sprite.set_modulate(Color(0.1, 0.4, 0.7))
	blink_timer.start()
	set_process(true)

func _process(delta):
	if dead_timestamp > 0:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var death_anim_ended = secs_since_death > death_particle_effect.get_lifetime()
		var flowing_anim_ended = secs_since_death > flowing_particle_effect.get_lifetime()
		if death_anim_ended and flowing_anim_ended:
			queue_free()
		return
	if game.menu_displayed:
		return
	var v = Vector2(0.0, -1.0).rotated(get_rot())
	var new_pos = get_pos()
	var delta_rad = 0.0
	var f1 = 280.0
	var f2 = 4.0
	if Input.is_action_pressed("ui_up"):
		new_pos += v * delta * f1
	if Input.is_action_pressed("ui_down"):
		new_pos -= v * delta * f1
	if Input.is_action_pressed("ui_left"):
		delta_rad += delta * f2
	if Input.is_action_pressed("ui_right"):
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
				sfx.play("laser")

	set_pos(new_pos)
	rotate(delta_rad)

func _on_ShipArea2D_area_enter( area ):
	if not active():
		return
	dead_timestamp = OS.get_ticks_msec()
	death_particle_effect.set_emitting(true)
	flowing_particle_effect.set_emitting(false)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)
	ship_destroyed(area)

func _on_ShipActivationTimer_timeout():
	blink_timer.stop()
	sprite.set_modulate(Color(1, 1, 1))

func _on_ActivationBlinkTimer_timeout():
	var mod = sprite.get_modulate()
	var new_mod = Color(1 - mod.r, 1 - mod.g, 1 - mod.b)
	#print(new_mod)
	sprite.set_modulate(new_mod)
