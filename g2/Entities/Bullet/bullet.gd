extends Area2D

var v_
var dead_timestamp = -1

onready var effect = get_node("Particles2D")
onready var sprite = get_node("BulletSprite")
onready var light = get_node("Light2D")

func _ready():
	set_z(-999)
	set_process(true)

func _process(delta):
	if dead_timestamp > 0:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var effect_anim_ended = secs_since_death > effect.get_lifetime()
		if effect_anim_ended:
			queue_free()
		return
	var v = get_pos()
	set_pos(v + v_)
	if v.y < 0 or v.y > get_viewport_rect().size.y or v.x < 0 or v.x > get_viewport_rect().size.x:
		dead_timestamp = OS.get_ticks_msec()
		effect.set_emitting(false)
		light.set_enabled(false)
		sprite.hide()
		set_layer_mask(0)
		set_collision_mask(0)