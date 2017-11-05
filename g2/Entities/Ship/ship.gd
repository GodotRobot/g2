extends Area2D

var dead_timestamp = -1

onready var game = get_tree().get_root().get_node("game")
onready var death_particle_effect = get_node("ShipDeathParticles2D")
onready var flowing_particle_effect = get_node("ShipParticles2D")
onready var sprite = get_node("ShipSprite")
onready var col = get_node("ShipCollisionShape2D")

func ship_destroyed(area):
	game.ship_destroyed()
	#print(get_name(), " <-> ", area.get_name())
	#trigger kill effect TODO

func _ready():
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
		var bullet = preload("../Bullet/bullet.tscn").instance()
		get_parent().add_child(bullet)
		bullet.v_ = v * delta * f1 * 1.3
		bullet.set_pos(get_transform() * Vector2(0.0, -45.0))

	set_pos(new_pos)
	rotate(delta_rad)

func _on_ShipArea2D_area_enter( area ):
	dead_timestamp = OS.get_ticks_msec()
	death_particle_effect.set_emitting(true)
	flowing_particle_effect.set_emitting(false)
	sprite.hide()
	set_layer_mask(0)
	set_collision_mask(0)
	ship_destroyed(area)
