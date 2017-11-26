extends RigidBody2D

onready var GameManager = get_node("/root/GameManager")
onready var anim = get_node("Anim")
onready var hitbox = get_node("Hitbox")
onready var death_effect1 = get_node("DeathEffect1")
onready var death_effect2 = get_node("DeathEffect1/DeathEffect2")
onready var death_effect3 = get_node("DeathEffect1/DeathEffect3")

export(int, 5) var HP = 5

var dead_timestamp = -1

func _ready():
	set_sleeping(false) # todo can be removed?
	set_process(true)

func _process(delta):
	if dead_timestamp > 0:
		var secs_since_death = (OS.get_ticks_msec() - dead_timestamp) / 1000.0
		var death_anim_ended = secs_since_death > death_effect1.get_lifetime()
		if death_anim_ended:
			queue_free()
		if secs_since_death > GameManager.LEVEL_POST_MORTEM_DELAY_SEC:
			if get_groups().find("meteors") != -1:
				remove_from_group("meteors")
		return

func start_death():
	if dead_timestamp != -1:
		return
	dead_timestamp = OS.get_ticks_msec()
	anim.play("Death")
	death_effect1.set_emitting(false)
	death_effect2.set_emitting(false)
	death_effect3.set_emitting(false)
	set_collision_mask(0)
	set_layer_mask(0)
	hitbox.set_collision_mask(0)
	hitbox.set_layer_mask(0)

func _on_Hitbox_body_enter( body ):
	var dir = get_pos() - body.get_pos()
	body.start_death()
	anim.play("Hit")
	HP -= 1
	if HP == 0:
		start_death()
