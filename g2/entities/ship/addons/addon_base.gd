extends AnimatedSprite

enum TYPE {
	shield = 0,
	cannon = 1
}

const KIND_TO_TYPE = {
	"Shield" : TYPE.shield,
	"Cannon" : TYPE.cannon
}
# power is time in seconds until effect wears off
export(int, 0, 100) var power = 0
export(String, "Shield", "Cannon") var kind = "Shield"

const ALERT_TIME = 2.0

onready var timer = get_node("Timer")
onready var anim = get_node("AnimationPlayer")

var type = TYPE.shield

func _ready():
	type = KIND_TO_TYPE[kind]
	if power > 0:
		timer.set_wait_time(float(power))
		timer.start()
	start()
	set_process(true) # no need for fixed_process for now

func start():
	if type == TYPE.shield:
		anim.play("ShieldGrow")

func _process(delta):
	if timer.get_time_left() < ALERT_TIME and not anim.is_playing():
		print("anim started")
		anim.play("ShieldAlert")
	
func _on_Timer_timeout():
	queue_free()

func _on_ShieldArea_body_enter( body ):
	body.start_death()
