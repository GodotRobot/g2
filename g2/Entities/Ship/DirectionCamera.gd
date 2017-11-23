extends Camera2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

const direction_camera_factor = 0.2

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
func update(movement_offset):
	movement_offset *= direction_camera_factor
	set_pos(get_pos() + movement_offset)
