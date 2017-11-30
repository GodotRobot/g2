extends RigidBody2D

onready var GameManager = get_node("/root/GameManager")
onready var anim = get_node("Anim")
onready var hitbox = get_node("Hitbox")
onready var flow_effect1 = get_node("FlowEffect1")
onready var flow_effect2 = get_node("FlowEffect2")
onready var flow_effect3 = get_node("FlowEffect3")
onready var death_effect1 = get_node("DeathEffect1")
onready var death_effect2 = get_node("DeathEffect2")
onready var death_effect3 = get_node("DeathEffect3")

export(int, 5) var HP = 5

var dead_timestamp = -1

func _ready():
	anim.play("ModulateLightColor")
	set_process(true)

func _process(delta):
	if dead_timestamp > 0:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var flow_anim_ended = secs_since_death > flow_effect1.get_lifetime()
		var death_anim_ended = secs_since_death > death_effect1.get_lifetime()
		if flow_anim_ended and death_anim_ended:
			queue_free()
		if secs_since_death > GameManager.LEVEL_POST_MORTEM_DELAY_SEC:
			if get_groups().find("meteors") != -1:
				remove_from_group("meteors")
		return
	if !anim.is_playing():
		anim.set_speed(rand_range(0.6, 1.4))
		anim.play("ModulateLightColor")

func set_fake_speed(speed):
	set_linear_velocity(get_linear_velocity() + Vector2(0.0, speed))
	
func start_death():
	if dead_timestamp != -1:
		return
	dead_timestamp = OS.get_ticks_msec()
	anim.play("Death")
	flow_effect1.set_emitting(false)
	flow_effect2.set_emitting(false)
	flow_effect3.set_emitting(false)
	death_effect1.set_emitting(true)
	death_effect2.set_emitting(true)
	death_effect3.set_emitting(true)
	set_collision_mask(0)
	set_layer_mask(0)
	hitbox.set_collision_mask(0)
	hitbox.set_layer_mask(0)

func _on_Hitbox_body_enter( body ):
	body.start_death()
	anim.play("Hit")
	HP -= 1
	if HP == 0:
		start_death()
