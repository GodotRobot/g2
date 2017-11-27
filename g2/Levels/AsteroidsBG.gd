extends ParallaxLayer

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

onready var offset = Vector2(0,0)

func _ready():
	set_process(true)
	
func _process(delta):
	pass
	#offset.x += 100 * delta
	#set_motion_offset(offset)
