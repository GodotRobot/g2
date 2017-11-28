extends Label

onready var fade_out = true

func _ready():
	pass


func _on_Timer_timeout():
	var cur_color = self.get("custom_colors/font_color")
	
	if fade_out:
		cur_color.a -= 0.1
		if cur_color.a < 0.0:
			fade_out = false
	else:
		cur_color.a += 0.1
		if cur_color.a > 1.0:
			fade_out = true
		
	self.set("custom_colors/font_color",cur_color)
