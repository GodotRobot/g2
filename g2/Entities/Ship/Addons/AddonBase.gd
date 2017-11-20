extends Sprite

# power is time in seconds until effect wears off
export(int, 0, 100) var power = 0

onready var timer = get_node("Timer")

func _ready():
	timer.set_wait_time(float(power))
	timer.start()

func _on_Timer_timeout():
	queue_free()
