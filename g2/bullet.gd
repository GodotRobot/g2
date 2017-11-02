extends Sprite

var v_
	
func _ready():
	set_process(true)

func _process(delta):
	var v = get_pos()
	set_pos(v + v_)
	if v.y < 0 or v.y > get_viewport_rect().size.y or v.x < 0 or v.x > get_viewport_rect().size.x:
		queue_free()
	