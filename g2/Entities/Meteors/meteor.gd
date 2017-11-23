extends Sprite

onready var GameManager = get_node("/root/GameManager")

export(float, -5.0, 5.0, 0.1) var rotation_speed = 0.0
export(Vector2) var direction = Vector2(0.0, 0.0)

func _ready():
	set_process(true)

func _process(delta):
	translate(direction * delta * 10.0)
	rotate(rotation_speed * delta)
