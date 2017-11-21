extends Panel

func update_highscores(result_string):
	var scores = {}
	scores.parse_json(result_string)
	for i in range(5):
		get_node("VBoxContainer/GridContainer/Pos" + String(i+1)).set_text(String(i+1))
	var i=0
	for name in scores.names:
		get_node("VBoxContainer/GridContainer/Name" + String(i+1)).set_text(name)
		i += 1
	var i=0
	for score in scores.scores:
		get_node("VBoxContainer/GridContainer/Score" + String(i+1)).set_text(String(score))
		i += 1

func _ready():
	pass

func _init():
	pass