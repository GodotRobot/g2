extends CanvasLayer

onready var time_text = get_node("HUD/Time")
onready var level_text = get_node("HUD/Level")
onready var lives_container = get_node("HUD/LivesLeft")
onready var score = get_node("HUD/Score")

func _ready():
	pass

func set_level(level):
	level_text.set_text(str(level))

func set_score(points):
	score.set_text(str(points))
	
func set_time(time):
	
	time_text.set_text(str(time))

func calc_lifes():
	var children = lives_container.get_children()
	return children.size() / 2

func set_lives(count):
	var lives_to_add = count - calc_lifes()
	if lives_to_add == 0:
		return
	elif lives_to_add > 0:
		add_life(lives_to_add)
	else:
		remove_life(lives_to_add)

func add_life(count):
	for i in range(count):
		get_node("HUD/LivesLeft").add_child(get_node("HUD/LivesLeft/Life").duplicate()) # icon
		get_node("HUD/LivesLeft").add_child(get_node("HUD/LivesLeft/Sep").duplicate()) # separator

func remove_life(count):
	var children = lives_container.get_children()
	if children.empty():
		return false
	for i in range(count):
		lives_container.remove_child(children[children.size()-1]) # icon
		lives_container.remove_child(children[children.size()-2]) # separator
	return true

#func update_timer(left_ratio):
	#timer.set_value(timer.get_max() * left_ratio)

func _on_CheckBox_toggled( pressed ):
	GameManager.debug = pressed
