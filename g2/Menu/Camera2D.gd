extends Camera2D

const menu_background_speed = 80

func _ready():
	set_process(true)
	
func _process(delta):
	var cur_pos = self.get_pos()
	self.set_pos(Vector2(cur_pos.x + (menu_background_speed * delta), cur_pos.y))