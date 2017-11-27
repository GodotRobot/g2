extends CanvasLayer

onready var time_text = get_node("HUD/Time")
onready var level_text = get_node("HUD/Level")
onready var score_text = get_node("HUD/Score")
onready var lives_container = get_node("HUD/LivesLeft")

#onready var warp_text = get_node("HUD/Warp")
#onready var warp_label = get_node("HUD/WarpLabel")

onready var warp_container = get_node("HUD/WarpsLeft")
onready var warp_blink_timer = get_node("HUD/WarpBlinkTimer")
onready var warp_blink = true

func _ready():
	pass

func set_level(level):
	level_text.set_text(str(level).pad_zeros(2))

func calc_warps():
	var children = warp_container.get_children()
	return children.size() / 2
	
func set_warps(count):
	var warps_to_add = count - calc_warps()
	if warps_to_add == 0:
		return
	elif warps_to_add > 0:
		add_warps(warps_to_add)
	else:
		remove_warps(warps_to_add)

func add_warps(count):
	for i in range(count):
		warp_container.add_child(get_node("HUD/WarpsLeft/Warp").duplicate()) # icon
		warp_container.add_child(get_node("HUD/WarpsLeft/Sep").duplicate()) # separator

func remove_warps(count):
	var children = warp_container.get_children()
	if children.empty():
		return false
	for i in range(count):
		warp_container.remove_child(children[children.size()-1]) # icon
		warp_container.remove_child(children[children.size()-2]) # separator
	return true

func set_score(points):
	score_text.set_text(str(points).pad_zeros(4))

func set_time(time):
	time_text.set_text(str(time).pad_zeros(2))

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
		lives_container.add_child(get_node("HUD/LivesLeft/Life").duplicate()) # icon
		lives_container.add_child(get_node("HUD/LivesLeft/Sep").duplicate()) # separator

func remove_life(count):
	var children = lives_container.get_children()
	if children.empty():
		return false
	for i in range(count):
		lives_container.remove_child(children[children.size()-1]) # icon
		lives_container.remove_child(children[children.size()-2]) # separator
	return true


func _on_CheckBox_toggled( pressed ):
	GameManager.debug = pressed

func _on_WarpBlinkTimer_timeout():
	pass
	#if warp_blink:
	#	warp_text.hide()
	#	warp_label.hide()
	#	warp_blink = false
	#else:
	#	warp_text.show()
	#	warp_label.show()
	#	warp_blink = true
